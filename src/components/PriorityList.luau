--[[
	PriorityList
	Ordered list shown as a grid of numbered cards ("01  Auto Join Challenge  ⠿"). Drag a card
	(mouse or finger) onto another spot to reorder; the others make room while you drag.
	First = highest priority.

	local priority = section:PriorityList({
		Flag = "JoinPriority",              -- saved in configs (the order, as a list of names)
		Title = "Join priority",            -- optional card header
		Subtitle = "Top enabled route wins; routing repeats after every visit to the lobby.",
		Values = { "Auto Join Challenge", "Auto Join Story / Inf", "Auto Infinity Castle", ... },
		Columns = 2,                        -- max columns (phones drop to 1 automatically)
		Collapsed = false,                  -- start closed (click the header to toggle)
		ValueChanged = function(self, order: { string }) end,
	})

	priority.Value                 -- current order { "Auto Join Challenge", ... }
	priority:MoveTo("Raid", 1)
	priority:MoveUp("Raid") / priority:MoveDown("Raid")
	priority:SetOrder({ ... })
	cascade.Flags:OnChanged("JoinPriority", function(order) end)
]]

local types = require("@types")

--// Constants
local CELL_HEIGHT = 38
local DRAG_THRESHOLD = 6

return function(self, properties: types.PriorityListProperties): types.PriorityList
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local icons = require("@modules/icons")
	local symbols = require("@modules/symbols")
	local utility = require("@modules/utility")

	--// References
	local create = creator.Create
	local userInputService = services.UserInputService

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local items = {} -- name -> { Button, Badge, Title, Grip }
	local object

	--// UI
	properties = properties or {}

	local baseValues = {}

	for _, value in ipairs(properties.Values or properties.Options or {}) do
		if not table.find(baseValues, tostring(value)) then
			table.insert(baseValues, tostring(value))
		end
	end

	local hasHeader = properties.Title ~= nil or properties.Subtitle ~= nil

	local card = require("@structures/CardSection")(self, {
		Name = "PriorityList",
		Title = properties.Title or "",
		Subtitle = properties.Subtitle,
		Collapsible = hasHeader and properties.Collapsible ~= false,
		Collapsed = properties.Collapsed,
		Parent = parent,
	})

	-- Without a title / subtitle the cards sit straight in the groupbox (no panel around them)
	if not hasHeader then
		card.Header.Visible = false
		card.Body.BackgroundTransparency = 1

		local stroke = card.Body:FindFirstChildOfClass("UIStroke")

		if stroke then
			stroke.Enabled = false
		end

		local padding = card.Body:FindFirstChildOfClass("UIPadding")

		if padding then
			padding.PaddingLeft = UDim.new(0, 0)
			padding.PaddingRight = UDim.new(0, 0)
			padding.PaddingTop = UDim.new(0, 10)
			padding.PaddingBottom = UDim.new(0, 10)
		end
	end

	card.UseGrid({
		CellHeight = CELL_HEIGHT,
		MaxColumns = math.max(1, properties.Columns or 2),
		MinColumnWidth = 190,
	})

	local structures = {
		Body = card.Body,
		Card = card,
		Content = card.Content,
	}

	--// Functions
	-- Keeps every known value exactly once: given order first, then anything it left out
	local function normalize(order): { string }
		local result = {}

		if typeof(order) == "table" then
			for _, value in ipairs(order) do
				value = tostring(value)

				if table.find(baseValues, value) and not table.find(result, value) then
					table.insert(result, value)
				end
			end
		end

		for _, value in ipairs(baseValues) do
			if not table.find(result, value) then
				table.insert(result, value)
			end
		end

		return result
	end

	local function label(index: number): string
		return string.format("%02d", index)
	end

	-- Lays the cards out in `order` (the saved order, or the preview while dragging)
	local function layout(order)
		for index, name in ipairs(order) do
			local item = items[name]

			if item then
				item.Button.LayoutOrder = index
				item.Badge.Text = label(index)
			end
		end
	end

	local function render()
		layout(properties.Value or {})
	end

	local function moveTo(name: string, target: number)
		local order = table.clone(properties.Value or {})
		local index = table.find(order, name)

		if not index then
			return
		end

		target = math.clamp(math.floor(target), 1, #order)

		if target == index then
			return
		end

		table.remove(order, index)
		table.insert(order, target, name)
		object.Value = order
	end

	--// Dragging
	-- The dragged card leaves a highlighted gap in the grid; a floating copy follows the
	-- pointer in its own ScreenGui (never clipped by the window, unaffected by the mobile scale).
	local dragGui = create("ScreenGui")({
		Name = "PriorityDrag",
		DisplayOrder = 204,
		Enabled = false,
		IgnoreGuiInset = true,
		OnTopOfCoreBlur = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	utility.ProtectUI(dragGui.__instance)
	structures.DragLayer = dragGui.__instance

	local drag = nil -- { Name, Input, Start, Started, Ghost, Offset, Preview, Scrollers }

	local function setGap(item, isGap: boolean)
		local accent = theme.Controls.SwitchAccent[1].Value
		local stroke = item.Button:FindFirstChildOfClass("UIStroke")

		item.Badge.Visible = not isGap
		item.Title.Visible = not isGap
		item.Grip.Visible = not isGap

		if stroke then
			stroke.Color = isGap and accent or theme.Controls.ViewBorder[1].Value
			stroke.Transparency = isGap and 0.35 or theme.Controls.ViewBorder[2].Value
		end

		item.Button.BackgroundTransparency = isGap and 0.94 or theme.Controls.Card.Fill[2].Value
		item.Button.BackgroundColor3 = isGap and accent or theme.Controls.Card.Fill[1].Value
	end

	-- Stops pages from scrolling while a finger drags a card
	local function lockScrolling(button: GuiObject)
		local locked = {}
		local current = button.Parent

		while current do
			if current:IsA("ScrollingFrame") and current.ScrollingEnabled then
				current.ScrollingEnabled = false
				table.insert(locked, current)
			end

			current = current.Parent
		end

		return locked
	end

	-- Index the pointer is over: the card whose centre is closest
	local function targetIndex(position: Vector2): number
		local best, bestDistance = 1, math.huge

		for index, name in ipairs(drag.Preview) do
			local button = items[name].Button
			local center = button.AbsolutePosition + button.AbsoluteSize / 2
			local distance = (center - position).Magnitude

			if distance < bestDistance then
				best, bestDistance = index, distance
			end
		end

		return best
	end

	local function beginDrag()
		local item = items[drag.Name]
		local button = item.Button

		drag.Started = true
		drag.Preview = table.clone(properties.Value or {})
		drag.Scrollers = lockScrolling(button)

		-- Floating copy at the card's on-screen size
		local ghost = button:Clone()

		for _, descendant in ipairs(ghost:GetDescendants()) do
			if descendant:IsA("UIStroke") then
				descendant.Color = theme.Controls.SwitchAccent[1].Value
				descendant.Transparency = 0.2
			end
		end

		ghost.Name = "Ghost"
		ghost.Active = false
		ghost.AnchorPoint = Vector2.zero
		ghost.BackgroundColor3 = theme.Controls.Background[1].Value
		ghost.BackgroundTransparency = 0
		ghost.LayoutOrder = 0
		ghost.Size = UDim2.fromOffset(button.AbsoluteSize.X, button.AbsoluteSize.Y)

		local scale = utility.GetScale(button)

		if scale > 0.05 and scale ~= 1 then
			local uiScale = Instance.new("UIScale")
			uiScale.Scale = scale
			uiScale.Parent = ghost
			ghost.Size = UDim2.fromOffset(button.AbsoluteSize.X / scale, button.AbsoluteSize.Y / scale)
		end

		local ghostBadge = ghost:FindFirstChild("Badge")

		if ghostBadge then
			ghostBadge.TextColor3 = theme.Controls.SwitchAccent[1].Value
			ghostBadge.TextTransparency = 0
		end

		drag.Offset = Vector2.new(drag.Start.X, drag.Start.Y) - button.AbsolutePosition
		ghost.Position = UDim2.fromOffset(button.AbsolutePosition.X, button.AbsolutePosition.Y)
		ghost.Parent = dragGui.__instance
		dragGui.Enabled = true

		drag.Ghost = ghost
		setGap(item, true)
	end

	local function updateDrag(position: Vector2)
		if not drag then
			return
		end

		if not drag.Started then
			if (position - Vector2.new(drag.Start.X, drag.Start.Y)).Magnitude < DRAG_THRESHOLD then
				return
			end

			beginDrag()
		end

		local topLeft = position - drag.Offset

		drag.Ghost.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)

		-- Move the gap to wherever the pointer is
		local target = targetIndex(position)
		local current = table.find(drag.Preview, drag.Name)

		if target ~= current then
			table.remove(drag.Preview, current)
			table.insert(drag.Preview, target, drag.Name)
			layout(drag.Preview)
		end

		local ghostBadge = drag.Ghost:FindFirstChild("Badge")

		if ghostBadge then
			ghostBadge.Text = label(table.find(drag.Preview, drag.Name) or 1)
		end
	end

	local function endDrag()
		local current = drag
		drag = nil

		if not current or not current.Started then
			return
		end

		for _, scroller in ipairs(current.Scrollers or {}) do
			scroller.ScrollingEnabled = true
		end

		if current.Ghost then
			current.Ghost:Destroy()
		end

		dragGui.Enabled = false

		local item = items[current.Name]

		if item then
			setGap(item, false)
		end

		object.Value = current.Preview
	end

	local function startDrag(name: string, input: InputObject)
		if drag then
			return
		end

		drag = {
			Name = name,
			Input = input,
			Start = input.Position,
			Started = false,
		}

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				connection:Disconnect()

				if drag and drag.Input == input then
					endDrag()
				end
			end
		end)
	end

	userInputService.InputChanged:Connect(function(input)
		if not drag then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if drag.Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			-- only the finger that grabbed the card
			if drag.Input.UserInputType == Enum.UserInputType.Touch and input ~= drag.Input then
				return
			end
		else
			return
		end

		updateDrag(Vector2.new(input.Position.X, input.Position.Y))
	end)

	userInputService.InputEnded:Connect(function(input)
		if drag and (input == drag.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
			endDrag()
		end
	end)

	--// Cards
	local function makeItem(name: string)
		local button = create("TextButton")({
			Name = "Item",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Text = "",
			Parent = card.Content,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Fill[1],
				BackgroundTransparency = theme.Controls.Card.Fill[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 7),
			}),

			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

				__dynamicKeys = {
					Color = theme.Controls.ViewBorder[1],
					Transparency = theme.Controls.ViewBorder[2],
				},
			}),

			create("TextLabel")({
				Name = "Badge",
				AnchorPoint = Vector2.new(0, 0.5),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(26, 20),
				Text = "01",
				TextSize = 12,

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Card.Hover[1],
					BackgroundTransparency = theme.Controls.Card.Hover[2],
					TextColor3 = theme.Text.Secondary[1],
					TextTransparency = theme.Text.Secondary[2],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 5),
				}),
			}),

			create("TextLabel")({
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Position = UDim2.new(0, 46, 0.5, 0),
				Size = UDim2.new(1, -(46 + 32), 0, 16),
				Text = name,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			-- Drag handle hint
			create("ImageLabel")({
				Name = "Grip",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -11, 0.5, 0),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(14, 14),

				__dynamicKeys = {
					ImageColor3 = theme.Text.Secondary[1],
					ImageTransparency = theme.Text.Secondary[2],
				},
			}),
		}).__instance :: TextButton

		button:SetAttribute("SearchIndex", name)

		local grip = button:FindFirstChild("Grip") :: ImageLabel

		icons.Apply(grip, "grip-vertical", symbols.line3Horizontal, 14)

		button.MouseEnter:Connect(function()
			if not drag then
				button.BackgroundTransparency = theme.Controls.Card.Hover[2].Value
			end
		end)
		button.MouseLeave:Connect(function()
			if not (drag and drag.Name == name and drag.Started) then
				button.BackgroundTransparency = theme.Controls.Card.Fill[2].Value
			end
		end)
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				startDrag(name, input)
			end
		end)

		items[name] = {
			Button = button,
			Badge = button:FindFirstChild("Badge") :: TextLabel,
			Title = button:FindFirstChild("Title") :: TextLabel,
			Grip = grip,
		}
	end

	--// Component
	object = binder.Wrap(properties, {
		Title = function(value: string?)
			card.SetTitle(value)
		end,
		Subtitle = function(value: string?)
			card.SetSubtitle(value)
		end,
		Collapsed = function(value: boolean)
			card.SetCollapsed(value == true)
		end,
		Value = function(value)
			value = normalize(value)
			properties.Value = value
			render()

			if properties.ValueChanged then
				task.spawn(properties.ValueChanged, object, table.clone(value))
			end
		end,
	}, card.Body, { "Value" }) -- Value is stored normalised by its handler, not as given

	for _, name in ipairs(baseValues) do
		makeItem(name)
	end

	card.OnCollapsed(function(isCollapsed)
		properties.Collapsed = isCollapsed
	end)

	card.Body.__instance.Destroying:Connect(function()
		dragGui:Destroy()
	end)

	object.Type = "PriorityList"
	object.Theme = theme
	object.Structures = structures

	object.GetOrder = function()
		return table.clone(properties.Value or {})
	end
	object.SetOrder = function(_, order: { string })
		object.Value = order
	end
	object.MoveTo = function(_, name: string, position: number)
		moveTo(tostring(name), position)
	end
	object.MoveUp = function(_, name: string)
		local index = table.find(properties.Value or {}, tostring(name))

		if index then
			moveTo(tostring(name), index - 1)
		end
	end
	object.MoveDown = function(_, name: string)
		local index = table.find(properties.Value or {}, tostring(name))

		if index then
			moveTo(tostring(name), index + 1)
		end
	end
	-- Position of a value in the order (1 = top), or nil
	object.IndexOf = function(_, name: string)
		return table.find(properties.Value or {}, tostring(name))
	end

	properties.Value = normalize(properties.Value)
	binder.Apply(properties, object)
	render()

	return object
end
