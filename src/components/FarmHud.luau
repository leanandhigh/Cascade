--[[
	FarmHud
	Small floating, draggable panel shown over the game while farming: caption + optional
	button, a big session timer with a status pill, stat rows and a list of gained items.
	Works with mouse and touch.

	local hud = app:FarmHud({
		Title = "MTwin HUB",
		Icon = LOGO,                          -- optional logo / Lucide icon
		Source = farmStats,                   -- share stats with the FarmStats screen
		-- or its own: Stats = { { Name = "Wins", Icon = "trophy", Value = 0 }, ... }
		Only = { "Wins", "Gems" },            -- optional: which stats to show (default all)
		StatusFlag = "AutoFarm",              -- "Farming" while that toggle is on, "Idle" off
		Button = { Text = "Black", Callback = function() farmStats:Toggle() end }, -- optional
		MaxItems = 6,
	})

	hud:SetStatus("Joining raid", "Changed")   -- "Added" green | "Changed" orange | "Removed" red | "Info"
	hud:Set("Wins", 3)                         -- stats (same as farmStats:Set)
	hud:SetItems({ { Name = "Ore", Amount = 12, Icon = 1234 }, { Name = "Gem", Amount = 3 } })
	hud:ResetTimer()
	hud.Visible = false
]]

local types = require("@types")

--// Constants
local WIDTH = 260
local ROW_HEIGHT = 20

return function(self, properties: types.FarmHudProperties): types.FarmHud
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local utility = require("@modules/utility")
	local icons = require("@modules/icons")
	local flags = require("@modules/flags")
	local draggable = require("@modules/draggable")
	local Store = require("@modules/statStore")

	--// References
	local create = creator.Create

	--// Constants
	local REGULAR = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	local SEMIBOLD = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	local BOLD = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

	--// Variables
	local theme = self.Theme
	local structures = {}
	local rows = {} -- name -> { Frame, Value }
	local itemRows = {}
	local statusKind = "Info"
	local timerStart = os.clock()
	local buttonConfig = nil
	local customIcon = false
	local object

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Farm"
	properties.Draggable = properties.Draggable ~= false
	properties.Position = properties.Position or UDim2.new(1, -16, 0, 64)
	properties.MaxItems = properties.MaxItems or 6

	local ownsStore = properties.Source == nil
	local store = properties.Source and (properties.Source.Store or properties.Source) or Store.new(properties.Stats)

	local function label(props)
		props.BackgroundTransparency = 1
		props.ZIndex = props.ZIndex or 50

		return create("TextLabel")(props)
	end

	structures.Body = create("Frame")({
		Name = "FarmHud",
		Active = true,
		AnchorPoint = Vector2.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(WIDTH, 0),
		ZIndex = 50,
		Parent = utility.OverlayRoot(self),

		-- Same surface as the keybind list / watermark
		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.Card.Overlay[1],
			BackgroundTransparency = theme.Controls.Card.Overlay[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 8),
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

			__dynamicKeys = {
				Color = theme.Controls.ViewBorder[1],
				Transparency = theme.Controls.ViewBorder[2],
			},
		}),

		create("UIPadding")({
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		-- Header: icon, caption, optional button
		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			ZIndex = 50,

			create("ImageLabel")({
				Name = "Icon",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(16, 16),
				Visible = false,
				ZIndex = 50,

				-- Glyphs follow the accent, your own logo keeps its colours
				__contextKeys = {
					ImageColor3 = function()
						return customIcon and Color3.new(1, 1, 1) or theme.Controls.Selection[1].Value
					end,
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 4),
				}),
			}),

			label({
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				FontFace = SEMIBOLD,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, -64, 0, 16),
				Text = "",
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			create("TextButton")({
				Name = "Button",
				AnchorPoint = Vector2.new(1, 0.5),
				AutoButtonColor = false,
				BorderSizePixel = 0,
				FontFace = REGULAR,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(56, 22),
				Text = "",
				TextSize = 12,
				Visible = false,
				ZIndex = 51,

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Card.Hover[1],
					BackgroundTransparency = theme.Controls.Card.Hover[2],
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),

		-- Big timer + status pill
		create("Frame")({
			Name = "TimerRow",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 36),
			ZIndex = 50,

			label({
				Name = "Timer",
				AnchorPoint = Vector2.new(0, 0.5),
				FontFace = BOLD,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, -96, 0, 34),
				Text = "00:00:00",
				TextSize = 30,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			create("Frame")({
				Name = "Status",
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.86,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(0, 22),
				Visible = false,
				ZIndex = 50,

				create("UICorner")({
					CornerRadius = UDim.new(1, 0),
				}),

				create("UIPadding")({
					PaddingLeft = UDim.new(0, 9),
					PaddingRight = UDim.new(0, 9),
				}),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("Frame")({
					Name = "Dot",
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(6, 6),
					ZIndex = 50,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),
				}),

				label({
					Name = "Label",
					FontFace = REGULAR,
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 16),
					Text = "",
					TextSize = 12,
				}),
			}),
		}),

		create("Frame")({
			Name = "Divider",
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 50,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.ViewBorder[1],
				BackgroundTransparency = theme.Controls.ViewBorder[2],
			},
		}),

		create("Frame")({
			Name = "Rows",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.fromScale(1, 0),
			ZIndex = 50,

			create("UIListLayout")({
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),

		create("Frame")({
			Name = "ItemsDivider",
			BorderSizePixel = 0,
			LayoutOrder = 4,
			Size = UDim2.new(1, 0, 0, 1),
			Visible = false,
			ZIndex = 50,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.ViewBorder[1],
				BackgroundTransparency = theme.Controls.ViewBorder[2],
			},
		}),

		create("Frame")({
			Name = "Items",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 5,
			Size = UDim2.fromScale(1, 0),
			Visible = false,
			ZIndex = 50,

			create("UIListLayout")({
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
	}) :: Frame

	local body = structures.Body.__instance :: Frame

	structures.Header = body:FindFirstChild("Header") :: Frame
	structures.Icon = structures.Header:FindFirstChild("Icon") :: ImageLabel
	structures.Title = structures.Header:FindFirstChild("Title") :: TextLabel
	structures.Button = structures.Header:FindFirstChild("Button") :: TextButton
	structures.TimerRow = body:FindFirstChild("TimerRow") :: Frame
	structures.Timer = structures.TimerRow:FindFirstChild("Timer") :: TextLabel
	structures.Status = structures.TimerRow:FindFirstChild("Status") :: Frame
	structures.StatusDot = structures.Status:FindFirstChild("Dot") :: Frame
	structures.StatusLabel = structures.Status:FindFirstChild("Label") :: TextLabel
	structures.Divider = body:FindFirstChild("Divider") :: Frame
	structures.Rows = body:FindFirstChild("Rows") :: Frame
	structures.ItemsDivider = body:FindFirstChild("ItemsDivider") :: Frame
	structures.Items = body:FindFirstChild("Items") :: Frame

	utility.FitText(structures.StatusLabel, 0, 16)

	--// Stat rows
	local function shown(name: string): boolean
		local only = properties.Only

		return typeof(only) ~= "table" or table.find(only, name) ~= nil
	end

	local function renderRow(name: string)
		local row = rows[name]

		if row then
			local text, rate = store:Format(name)

			row.Value.Text = text
			row.Rate.Text = rate or ""
			row.Rate.Visible = rate ~= nil
		end
	end

	local function makeRow(definition, order: number)
		local frame = create("Frame")({
			Name = "Row",
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			Parent = structures.Rows,
			ZIndex = 50,

			create("ImageLabel")({
				Name = "Icon",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(14, 14),
				ZIndex = 50,

				__dynamicKeys = {
					ImageColor3 = theme.Controls.Selection[1],
				},
			}),

			label({
				Name = "Label",
				AnchorPoint = Vector2.new(0, 0.5),
				FontFace = REGULAR,
				Position = UDim2.new(0, 22, 0.5, 0),
				Size = UDim2.new(0.45, -22, 0, 16),
				Text = definition.Label,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Secondary[1],
					TextTransparency = theme.Text.Secondary[2],
				},
			}),

			create("Frame")({
				Name = "Values",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.55, 0, 0, 16),
				ZIndex = 50,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				label({
					Name = "Value",
					AutomaticSize = Enum.AutomaticSize.X,
					FontFace = SEMIBOLD,
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 16),
					Text = "--",
					TextSize = 13,

					__dynamicKeys = {
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),

				label({
					Name = "Rate",
					AutomaticSize = Enum.AutomaticSize.X,
					FontFace = REGULAR,
					LayoutOrder = 2,
					Size = UDim2.fromOffset(0, 16),
					Text = "",
					TextSize = 11,
					Visible = false,

					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}),
			}),
		}).__instance :: Frame

		local icon = frame:FindFirstChild("Icon") :: ImageLabel
		local text = frame:FindFirstChild("Label") :: TextLabel

		if definition.Icon then
			icons.Apply(icon, definition.Icon, nil, 14)
		else
			icon.Visible = false
			text.Position = UDim2.new(0, 0, 0.5, 0)
			text.Size = UDim2.new(0.45, 0, 0, 16)
		end

		local values = frame:FindFirstChild("Values")

		rows[definition.Name] = {
			Frame = frame,
			Value = values:FindFirstChild("Value") :: TextLabel,
			Rate = values:FindFirstChild("Rate") :: TextLabel,
		}
		renderRow(definition.Name)
	end

	local function rebuild()
		for name, row in pairs(rows) do
			if not store.ByName[name] or not shown(name) then
				row.Frame:Destroy()
				rows[name] = nil
			end
		end

		for index, definition in ipairs(store.Stats) do
			-- the big timer already shows the session time
			if definition.Type ~= "Timer" and shown(definition.Name) then
				if rows[definition.Name] then
					rows[definition.Name].Frame.LayoutOrder = index
				else
					makeRow(definition, index)
				end
			end
		end

		local hasRows = next(rows) ~= nil

		structures.Divider.Visible = hasRows
		structures.Rows.Visible = hasRows
	end

	--// Items ("+12 Ore")
	local function setItems(list)
		for _, row in ipairs(itemRows) do
			row:Destroy()
		end

		table.clear(itemRows)
		list = list or {}

		local shownCount = 0

		for index, item in ipairs(list) do
			if shownCount >= properties.MaxItems then
				break
			end

			shownCount += 1

			local amount = tonumber(item.Amount or item[2]) or 0
			local hasIcon = item.Icon ~= nil

			local frame = create("Frame")({
				Name = "Item",
				BackgroundTransparency = 1,
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
				Parent = structures.Items,
				ZIndex = 50,

				create("ImageLabel")({
					Name = "Icon",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromOffset(16, 16),
					Visible = hasIcon,
					ZIndex = 50,
				}),

				label({
					Name = "Name",
					AnchorPoint = Vector2.new(0, 0.5),
					FontFace = REGULAR,
					Position = UDim2.new(0, hasIcon and 22 or 0, 0.5, 0),
					Size = UDim2.new(1, -((hasIcon and 22 or 0) + 64), 0, 16),
					Text = tostring(item.Name or item[1] or "Item"),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),

				label({
					Name = "Amount",
					AnchorPoint = Vector2.new(1, 0.5),
					FontFace = SEMIBOLD,
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(60, 16),
					Text = (amount > 0 and "+" or "") .. Store.FormatNumber(amount, "short"),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,

					__dynamicKeys = {
						TextColor3 = amount > 0 and theme.Controls.Status.Added[1] or theme.Text.Primary[1],
						TextTransparency = amount > 0 and theme.Controls.Status.Added[2] or theme.Text.Primary[2],
					},
				}),
			}).__instance :: Frame

			if hasIcon then
				icons.Apply(frame:FindFirstChild("Icon"), item.Icon, nil, 16)
			end

			table.insert(itemRows, frame)
		end

		if #list > shownCount then
			table.insert(
				itemRows,
				label({
					Name = "More",
					FontFace = REGULAR,
					LayoutOrder = 999,
					Size = UDim2.new(1, 0, 0, 16),
					Text = string.format("+%d more", #list - shownCount),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = structures.Items,

					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}).__instance
			)
		end

		structures.Items.Visible = #list > 0
		structures.ItemsDivider.Visible = #list > 0
	end

	--// Status
	local function paintStatus()
		local color = theme.Controls.Status[statusKind] or theme.Controls.Status.Info

		structures.Status.BackgroundColor3 = color[1].Value
		structures.StatusDot.BackgroundColor3 = color[1].Value
		structures.StatusLabel.TextColor3 = color[1].Value
	end

	local function setStatus(text: string?, kind: string?)
		statusKind = (kind and theme.Controls.Status[kind]) and kind or statusKind
		structures.Status.Visible = text ~= nil and text ~= ""
		structures.StatusLabel.Text = text or ""
		paintStatus()
	end

	--// Live updates
	local disconnect = store:OnChanged(function(name)
		if name and store.ByName[name] and shown(name) and not rows[name] then
			rebuild()
			return
		end

		if name then
			renderRow(name)
		else
			for rowName in pairs(rows) do
				renderRow(rowName)
			end
		end
	end)

	local alive = true

	task.spawn(function()
		while alive do
			if body.Visible then
				structures.Timer.Text = Store.Clock(os.clock() - timerStart)
			end

			if structures.PlaceMobileToggle then
				structures.PlaceMobileToggle()
			end

			task.wait(1)
		end
	end)

	theme.Controls.Status.Info[1]:Connect(paintStatus)

	body.Destroying:Connect(function()
		alive = false
		disconnect()

		if ownsStore then
			store:Destroy()
		end
	end)

	draggable(body, body, function()
		return properties.Draggable
	end)

	-- Phones: the round menu toggle lives in the same top-right corner. While they'd overlap,
	-- the toggle sits just under the HUD; it goes back home when the HUD is hidden / moved away.
	-- (Not once the player has dragged the toggle themselves.)
	local toggleHome = nil
	local GAP = 10

	local function placeMobileToggle()
		local root = body.Parent
		local toggle = root and root:FindFirstChild("MobileToggle")

		if not toggle or not toggle:IsA("GuiObject") or toggle:GetAttribute("UserMoved") then
			return
		end

		toggleHome = toggleHome or toggle.Position

		local rootSize = root.AbsoluteSize
		local rootPosition = root:IsA("GuiObject") and root.AbsolutePosition or Vector2.zero
		local size = toggle.AbsoluteSize
		local homeX = rootSize.X * toggleHome.X.Scale + toggleHome.X.Offset - size.X * toggle.AnchorPoint.X
		local homeY = rootSize.Y * toggleHome.Y.Scale + toggleHome.Y.Offset - size.Y * toggle.AnchorPoint.Y

		local hudPosition = body.AbsolutePosition - rootPosition
		local hudSize = body.AbsoluteSize

		local overlaps = body.Visible
			and homeX < hudPosition.X + hudSize.X
			and hudPosition.X < homeX + size.X
			and homeY < hudPosition.Y + hudSize.Y + GAP
			and hudPosition.Y < homeY + size.Y

		if overlaps then
			local y = hudPosition.Y + hudSize.Y + GAP + size.Y * toggle.AnchorPoint.Y

			toggle.Position = UDim2.new(toggleHome.X.Scale, toggleHome.X.Offset, 0, y)
		else
			toggle.Position = toggleHome
		end
	end

	for _, property in ipairs({ "AbsolutePosition", "AbsoluteSize", "Visible" }) do
		body:GetPropertyChangedSignal(property):Connect(placeMobileToggle)
	end

	task.defer(placeMobileToggle)
	structures.PlaceMobileToggle = placeMobileToggle

	structures.Button.MouseButton1Click:Connect(function()
		local button = buttonConfig

		if typeof(button) == "table" and button.Callback then
			task.spawn(button.Callback, object)
		end
	end)

	--// Component
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = tostring(value or "")
		end,
		Icon = function(value)
			-- No icon given: a chart glyph in the accent, like the keybind list's keyboard icon
			value = value or "chart-column"

			local hasIcon = icons.Apply(structures.Icon, value, nil, 16)

			structures.Icon.Visible = hasIcon == true

			-- Your logo keeps its colours, glyphs take the accent
			customIcon = not icons.IsGlyph(value)
			structures.Icon.ImageColor3 = customIcon and Color3.new(1, 1, 1) or theme.Controls.Selection[1].Value

			structures.Title.Position = UDim2.new(0, hasIcon and 23 or 0, 0.5, 0)
		end,
		Button = function(value)
			-- `Button` is also the Button constructor the component wrapper copies onto objects
			if typeof(value) == "function" then
				return
			end

			buttonConfig = value

			local text = typeof(value) == "table" and value.Text or nil

			structures.Button.Text = tostring(text or "")
			structures.Button.Visible = text ~= nil and text ~= ""
		end,
		Timer = function(value: boolean)
			structures.TimerRow.Visible = value ~= false
		end,
		Only = function(value)
			properties.Only = value
			rebuild()
		end,
		Draggable = function(value: boolean)
			properties.Draggable = value
		end,
		Status = function(value: string?)
			setStatus(value, properties.StatusKind)
		end,
		Items = function(value)
			setItems(value)
		end,
	}, structures.Body)

	object.Type = "FarmHud"
	object.Theme = theme
	object.Structures = structures
	object.Store = store

	object.SetStatus = function(_, text: string?, kind: string?)
		properties.Status = text
		properties.StatusKind = kind
		setStatus(text, kind)
	end
	object.SetItems = function(_, list)
		properties.Items = list
		setItems(list)
	end
	object.SetButton = function(_, text: string?, callback)
		object.Button = text and { Text = text, Callback = callback } or false
	end
	object.ResetTimer = function()
		timerStart = os.clock()
		structures.Timer.Text = Store.Clock(0)
	end
	object.SetElapsed = function(_, seconds: number)
		timerStart = os.clock() - (tonumber(seconds) or 0)
	end
	object.Set = function(_, name: string, value)
		store:Set(tostring(name), value)
	end
	object.SetRow = object.Set
	object.Get = function(_, name: string)
		return store:Get(tostring(name))
	end
	object.Increment = function(_, name: string, amount: number?)
		store:Increment(tostring(name), amount)
	end
	object.Reset = function(_, name: string?)
		store:Reset(name and tostring(name) or nil)

		if name == nil then
			object:ResetTimer()
		end
	end
	binder.Apply(properties, object)

	if properties.Icon == nil then
		object.Icon = nil
	end

	rebuild()

	-- "Farming" / "Idle" from a toggle
	if properties.StatusFlag ~= nil then
		local onText = properties.StatusOn or "Farming"
		local offText = properties.StatusOff or "Idle"

		local function fromFlag(value)
			object:SetStatus(value and onText or offText, value and "Added" or "Removed")
		end

		fromFlag(flags:Get(properties.StatusFlag) == true)
		flags:OnChanged(properties.StatusFlag, function(value)
			fromFlag(value == true)
		end)
	end

	return object
end
