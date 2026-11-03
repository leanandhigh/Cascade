--[[
	PriorityList
	Ordered list shown as a grid of numbered cards ("01  Auto Join Challenge  v"). Click a card
	to open "Move to position" and pick its new number. First = highest priority.

	local priority = box:PriorityList({
		Flag = "JoinPriority",              -- saved in configs (the order, as a list of names)
		Title = "Join priority",            -- optional card header
		Subtitle = "Top enabled route wins; routing repeats after every visit to the lobby.",
		Values = { "Auto Join Challenge", "Auto Join Story / Inf", "Auto Infinity Castle", ... },
		Columns = 2,                        -- max columns (phones drop to 1 automatically)
		Collapsed = false,                  -- start closed (click the header to toggle)
		ValueChanged = function(self, order: { string }) end,
	})

	priority.Value                -- current order { "Auto Join Challenge", ... }
	priority:MoveTo("Raid", 1)     -- same as picking 01 in the menu
	priority:MoveUp("Raid") / priority:MoveDown("Raid")
	priority:SetOrder({ ... })
	cascade.Flags:OnChanged("JoinPriority", function(order) end)
]]

local types = require("@types")

--// Constants
local CELL_HEIGHT = 38
local PICKER_COLUMNS = 4
local PICKER_CELL = Vector2.new(42, 32)
local PICKER_GAP = 8

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
	local tweenService = services.TweenService
	local userInputService = services.UserInputService

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local items = {} -- name -> { Button, Badge, Chevron }
	local object
	local openName = nil

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

	local function paintItem(name: string)
		local item = items[name]

		if not item then
			return
		end

		local isOpen = openName == name
		local accent = theme.Controls.SwitchAccent[1].Value

		item.Badge.TextColor3 = isOpen and accent or theme.Text.Secondary[1].Value
		item.Badge.TextTransparency = isOpen and 0 or theme.Text.Secondary[2].Value
		item.Button.BackgroundTransparency = isOpen and theme.Controls.Card.Hover[2].Value
			or theme.Controls.Card.Fill[2].Value

		tweenService
			:Create(
				item.Chevron,
				TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
				{ Rotation = isOpen and 180 or 0 }
			)
			:Play()
	end

	local function render()
		for index, name in ipairs(properties.Value or {}) do
			local item = items[name]

			if item then
				item.Button.LayoutOrder = index
				item.Badge.Text = label(index)
			end
		end
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

	--// Position picker (own ScreenGui so the window never clips it)
	local pickerGui = create("ScreenGui")({
		Name = "PriorityPicker",
		DisplayOrder = 203,
		Enabled = false,
		IgnoreGuiInset = true,
		OnTopOfCoreBlur = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local pickerWidth = PICKER_COLUMNS * PICKER_CELL.X + (PICKER_COLUMNS - 1) * PICKER_GAP + 24

	local panel = create("CanvasGroup")({
		Name = "Panel",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Size = UDim2.fromOffset(pickerWidth, 0),
		Parent = pickerGui.__instance,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.MenuButton.MenuBackground[1],
			BackgroundTransparency = theme.Controls.MenuButton.MenuBackground[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 10),
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

			__dynamicKeys = {
				Color = theme.Controls.ViewBorder[1],
				Transparency = theme.Controls.ViewBorder[2],
			},
		}),

		create("UIPadding")({
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),

			create("TextLabel")({
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, -26, 0, 16),
				Text = properties.PickerTitle or "Move to position",
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Secondary[1],
					TextTransparency = theme.Text.Secondary[2],
				},
			}),

			create("ImageButton")({
				Name = "Close",
				AnchorPoint = Vector2.new(1, 0.5),
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(22, 22),

				create("ImageLabel")({
					Name = "Icon",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromOffset(12, 12),

					__dynamicKeys = {
						ImageColor3 = theme.Text.Secondary[1],
						ImageTransparency = theme.Text.Secondary[2],
					},
				}),
			}),
		}),

		create("Frame")({
			Name = "Positions",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 0),

			create("UIGridLayout")({
				CellPadding = UDim2.fromOffset(PICKER_GAP, PICKER_GAP),
				CellSize = UDim2.fromOffset(PICKER_CELL.X, PICKER_CELL.Y),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
	})

	local panelInstance = panel.__instance :: CanvasGroup
	local closeButton = panelInstance:FindFirstChild("Header"):FindFirstChild("Close") :: ImageButton
	local positions = panelInstance:FindFirstChild("Positions") :: Frame
	local positionButtons = {}
	local pickerToken = 0

	icons.Apply(closeButton:FindFirstChild("Icon"), "x", symbols.xmark, 12)
	utility.ProtectUI(pickerGui.__instance)

	structures.Picker = pickerGui.__instance
	structures.PickerPanel = panelInstance

	local function placePicker(anchor: GuiObject)
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local size = panelInstance.AbsoluteSize

		local x = anchor.AbsolutePosition.X
		local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 6

		if y + size.Y > viewport.Y - 6 then
			y = anchor.AbsolutePosition.Y - size.Y - 6
		end

		panelInstance.Position = UDim2.fromOffset(
			math.clamp(x, 6, math.max(6, viewport.X - size.X - 6)),
			math.clamp(y, 6, math.max(6, viewport.Y - size.Y - 6))
		)
	end

	local function paintPositions()
		local current = openName and table.find(properties.Value or {}, openName)
		local accent = theme.Controls.SwitchAccent[1].Value

		for index, button in ipairs(positionButtons) do
			local selected = index == current

			button.TextColor3 = selected and accent or theme.Text.Primary[1].Value
			button.TextTransparency = selected and 0 or theme.Text.Primary[2].Value
			button.BackgroundTransparency = selected and theme.Controls.Card.Hover[2].Value
				or theme.Controls.Card.Fill[2].Value

			local stroke = button:FindFirstChildOfClass("UIStroke")

			if stroke then
				stroke.Enabled = selected
				stroke.Color = accent
			end
		end
	end

	local closePicker

	local function buildPositions()
		for _, button in ipairs(positionButtons) do
			button:Destroy()
		end

		table.clear(positionButtons)

		for index = 1, #baseValues do
			local button = create("TextButton")({
				Name = "Position" .. index,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				LayoutOrder = index,
				Text = label(index),
				TextSize = 13,
				Parent = positions,

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Card.Fill[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 6),
				}),

				create("UIStroke")({
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Enabled = false,
					Transparency = 0.5,
				}),
			}).__instance :: TextButton

			button.MouseButton1Click:Connect(function()
				local name = openName

				closePicker()

				if name then
					moveTo(name, index)
				end
			end)

			table.insert(positionButtons, button)
		end
	end

	local function openPicker(name: string)
		local item = items[name]

		if not item then
			return
		end

		local previous = openName

		openName = name
		pickerToken += 1

		if previous and previous ~= name then
			paintItem(previous)
		end

		paintItem(name)
		paintPositions()

		pickerGui.Enabled = true
		placePicker(item.Button)
		task.defer(placePicker, item.Button)

		tweenService
			:Create(panelInstance, TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
				GroupTransparency = 0,
			})
			:Play()
	end

	closePicker = function()
		if not openName then
			return
		end

		local previous = openName

		openName = nil
		pickerToken += 1

		local token = pickerToken

		paintItem(previous)

		local tween = tweenService:Create(
			panelInstance,
			TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ GroupTransparency = 1 }
		)

		tween.Completed:Connect(function()
			if token == pickerToken and not openName then
				pickerGui.Enabled = false
			end
		end)
		tween:Play()
	end

	closeButton.MouseButton1Click:Connect(function()
		closePicker()
	end)

	-- Click / tap outside closes it
	userInputService.InputBegan:Connect(function(input)
		if not openName then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local function inside(gui: GuiObject?)
			if not gui then
				return false
			end

			local pos, size = gui.AbsolutePosition, gui.AbsoluteSize

			return input.Position.X >= pos.X
				and input.Position.X <= pos.X + size.X
				and input.Position.Y >= pos.Y
				and input.Position.Y <= pos.Y + size.Y
		end

		local item = items[openName]

		if not inside(panelInstance) and not inside(item and item.Button) then
			closePicker()
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
				TextSize = 11,

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Card.Hover[1],
					BackgroundTransparency = theme.Controls.Card.Hover[2],
					TextColor3 = theme.Text.Secondary[1],
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
				Size = UDim2.new(1, -(46 + 30), 0, 16),
				Text = name,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			create("ImageLabel")({
				Name = "Chevron",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -12, 0.5, 0),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(12, 12),

				__dynamicKeys = {
					ImageColor3 = theme.Text.Secondary[1],
					ImageTransparency = theme.Text.Secondary[2],
				},
			}),
		}).__instance :: TextButton

		button:SetAttribute("SearchIndex", name)

		local chevron = button:FindFirstChild("Chevron") :: ImageLabel

		icons.Apply(chevron, "chevron-down", symbols.chevronDown, 12)

		button.MouseEnter:Connect(function()
			if openName ~= name then
				button.BackgroundTransparency = theme.Controls.Card.Hover[2].Value
			end
		end)
		button.MouseLeave:Connect(function()
			if openName ~= name then
				button.BackgroundTransparency = theme.Controls.Card.Fill[2].Value
			end
		end)
		button.MouseButton1Click:Connect(function()
			if openName == name then
				closePicker()
			else
				openPicker(name)
			end
		end)

		items[name] = {
			Button = button,
			Badge = button:FindFirstChild("Badge") :: TextLabel,
			Chevron = chevron,
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

			if openName then
				paintPositions()
			end

			if properties.ValueChanged then
				task.spawn(properties.ValueChanged, object, table.clone(value))
			end
		end,
	}, card.Body, { "Value" }) -- Value is stored normalised by its handler, not as given

	for _, name in ipairs(baseValues) do
		makeItem(name)
	end

	buildPositions()

	card.OnCollapsed(function(isCollapsed)
		properties.Collapsed = isCollapsed

		if isCollapsed then
			closePicker()
		end
	end)

	card.Body.__instance.Destroying:Connect(function()
		pickerGui:Destroy()
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
	object.OpenPicker = function(_, name: string)
		openPicker(tostring(name))
	end
	object.ClosePicker = function()
		closePicker()
	end

	properties.Value = normalize(properties.Value)
	binder.Apply(properties, object)
	render()

	-- Theme / accent changes repaint the hand-coloured parts
	theme.Controls.SwitchAccent[1]:Connect(function()
		if openName then
			paintItem(openName)
			paintPositions()
		end
	end)

	return object
end
