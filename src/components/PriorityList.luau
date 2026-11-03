--[[
	PriorityList
	An ordered list the player re-arranges with up / down arrows ("#1 Evolution  [▲][▼]").
	Use it for farm / target priority: your logic reads the order, first = highest priority.

	local priority = box:PriorityList({
		Flag = "FarmPriority",           -- saved in configs (the order, as a list of names)
		Subtitle = "Top ON job farms first", -- optional hint above the list
		Values = { "Evolution", "Farm", "Raid", "Infinite", "Material", "Craft", "Trials" },
		ValueChanged = function(self, order: { string }) end,
	})

	priority.Value            -- current order { "Evolution", "Farm", ... }
	priority:MoveUp("Raid")   -- same as pressing its arrow
	priority:SetOrder({ ... })
	cascade.Flags:OnChanged("FarmPriority", function(order) end)
]]

local types = require("@types")

--// Constants
local ITEM_HEIGHT = 30
local ARROW_SIZE = 22

return function(self, properties: types.PriorityListProperties): types.PriorityList
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local icons = require("@modules/icons")
	local symbols = require("@modules/symbols")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local structures = {}
	local items = {} -- name -> { Frame, Number, Up, Down }
	local object

	--// UI
	properties = properties or {}

	local baseValues = {}

	for _, value in ipairs(properties.Values or properties.Options or {}) do
		if not table.find(baseValues, tostring(value)) then
			table.insert(baseValues, tostring(value))
		end
	end

	structures.Body = create("Frame")({
		Name = "PriorityList",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = parent,

		create("UIPadding")({
			PaddingBottom = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
		}),

		create("UIListLayout")({
			Name = "UIListLayout",
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("TextLabel")({
			Name = "Subtitle",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://12187365364"),
			LayoutOrder = 0,
			Size = UDim2.fromScale(1, 0),
			Text = "",
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = false,

			__dynamicKeys = {
				TextColor3 = theme.Text.Secondary[1],
				TextTransparency = theme.Text.Secondary[2],
			},

			create("UIPadding")({
				PaddingBottom = UDim.new(0, 2),
			}),
		}),

		-- Same divider as Row, so Groupbox / Form separate it from the row above
		create("Folder")({
			Name = "LayoutIgnore",

			create("Frame")({
				Name = "Divider",
				AnchorPoint = Vector2.new(0, 1),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 1),
				Visible = false,

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.ViewBorder[1],
					BackgroundTransparency = theme.Controls.ViewBorder[2],
				},
			}),
		}),
	}) :: Frame

	structures.Subtitle = structures.Body:FindFirstChild("Subtitle") :: TextLabel

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

	local function setArrowEnabled(arrow: ImageButton, enabled: boolean)
		arrow.Active = enabled
		arrow.AutoButtonColor = false
		arrow:SetAttribute("Enabled", enabled)
		arrow.BackgroundTransparency = enabled and 0 or 0.75

		local image = arrow:FindFirstChild("Icon")

		if image then
			image.ImageTransparency = enabled and 0 or 0.5
		end
	end

	local function render()
		local order = properties.Value or {}

		for index, name in ipairs(order) do
			local item = items[name]

			if item then
				item.Frame.LayoutOrder = index
				item.Number.Text = "#" .. index
				setArrowEnabled(item.Up, index > 1)
				setArrowEnabled(item.Down, index < #order)
			end
		end
	end

	local function move(name: string, direction: number)
		local order = table.clone(properties.Value or {})
		local index = table.find(order, name)
		local target = index and index + direction

		if not index or target < 1 or target > #order then
			return
		end

		order[index], order[target] = order[target], order[index]
		object.Value = order
	end

	local function makeArrow(name: string, direction: number, layoutOrder: number): ImageButton
		local arrow = create("ImageButton")({
			Name = direction < 0 and "Up" or "Down",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = layoutOrder,
			Size = UDim2.fromOffset(ARROW_SIZE, ARROW_SIZE),

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.SwitchAccent[1],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 5),
			}),

			create("ImageLabel")({
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageColor3 = Color3.new(1, 1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(12, 12),
			}),
		}).__instance :: ImageButton

		icons.Apply(
			arrow:FindFirstChild("Icon"),
			direction < 0 and "chevron-up" or "chevron-down",
			direction < 0 and symbols.chevronUp or symbols.chevronDown,
			12
		)

		arrow.MouseButton1Click:Connect(function()
			if arrow:GetAttribute("Enabled") ~= false then
				move(name, direction)
			end
		end)

		return arrow
	end

	local function makeItem(name: string)
		local frame = create("Frame")({
			Name = "Item",
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
			Parent = structures.Body.__instance,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Fill[1],
				BackgroundTransparency = theme.Controls.Card.Fill[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 6),
			}),

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 4),
			}),

			create("TextLabel")({
				Name = "Number",
				AnchorPoint = Vector2.new(0, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(0, 16),
				Text = "#1",
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Controls.SwitchAccent[1],
				},
			}),

			create("TextLabel")({
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Position = UDim2.new(0, 26, 0.5, 0),
				Size = UDim2.new(1, -(26 + ARROW_SIZE * 2 + 4 + 8), 0, 16),
				Text = name,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			create("Frame")({
				Name = "Arrows",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(ARROW_SIZE * 2 + 4, ARROW_SIZE),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			}),
		}).__instance :: Frame

		frame:SetAttribute("SearchIndex", name)

		local arrows = frame:FindFirstChild("Arrows")
		local up = makeArrow(name, -1, 1)
		local down = makeArrow(name, 1, 2)

		up.Parent = arrows
		down.Parent = arrows

		-- Number column wide enough for "#10"
		local number = frame:FindFirstChild("Number") :: TextLabel

		items[name] = { Frame = frame, Number = number, Up = up, Down = down }
	end

	--// Component
	object = binder.Wrap(properties, {
		Subtitle = function(value: string?)
			structures.Subtitle.Text = value or ""
			structures.Subtitle.Visible = value ~= nil and value ~= ""
		end,
		Value = function(value)
			value = normalize(value)
			properties.Value = value
			render()

			if properties.ValueChanged then
				task.spawn(properties.ValueChanged, object, table.clone(value))
			end
		end,
	}, structures.Body, { "Value" }) -- Value is stored normalised by its handler, not as given

	for _, name in ipairs(baseValues) do
		makeItem(name)
	end

	object.Type = "PriorityList"
	object.Theme = theme
	object.Structures = structures

	object.GetOrder = function()
		return table.clone(properties.Value or {})
	end
	object.SetOrder = function(_, order: { string })
		object.Value = order
	end
	object.MoveUp = function(_, name: string)
		move(tostring(name), -1)
	end
	object.MoveDown = function(_, name: string)
		move(tostring(name), 1)
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
