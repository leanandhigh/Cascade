--[[
	FarmHud
	Small floating, draggable card that shows farm status and stats while the menu is hidden.
	Works with mouse and touch.

	local hud = app:FarmHud({
		Title = "MTwin HUB",
		Icon = LOGO,                      -- optional logo / Lucide icon
		Source = stats,                   -- a FarmStats: shows the same numbers
		-- or its own list: Stats = { { Name = "Wins", Icon = "trophy", Value = 0 }, ... }
		Only = { "Session", "Wins", "Gems" }, -- optional: which stats to show (default all)
		StatusFlag = "AutoFarm",          -- optional: "Farming" while that toggle is on, "Idle" off
		Position = UDim2.new(1, -16, 0, 64),
	})

	hud:SetStatus("Joining raid", "Changed") -- text + colour: "Added" (green) | "Changed" | "Removed" | "Info"
	hud:Set("Wins", 3)                         -- same as stats:Set
	hud.Visible = false
]]

local types = require("@types")

--// Constants
local WIDTH = 236
local ROW_HEIGHT = 24

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

	--// Variables
	local theme = self.Theme
	local structures = {}
	local rows = {} -- name -> { Frame, Value }
	local statusKind = "Info"
	local object

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Farm"
	properties.Draggable = properties.Draggable ~= false
	properties.Position = properties.Position or UDim2.new(1, -16, 0, 64)

	local ownsStore = properties.Source == nil
	local store = properties.Source and (properties.Source.Store or properties.Source) or Store.new(properties.Stats)

	structures.Body = create("Frame")({
		Name = "FarmHud",
		Active = true,
		AnchorPoint = Vector2.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(WIDTH, 0),
		ZIndex = 50,
		Parent = utility.OverlayRoot(self),

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.Card.Overlay[1],
			BackgroundTransparency = theme.Controls.Card.Overlay[2],
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
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

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
				Size = UDim2.fromOffset(18, 18),
				Visible = false,
				ZIndex = 50,

				create("UICorner")({
					CornerRadius = UDim.new(0, 4),
				}),
			}),

			create("TextLabel")({
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, -90, 0, 16),
				Text = "",
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 50,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			create("Frame")({
				Name = "Status",
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(0, 20),
				Visible = false,
				ZIndex = 50,

				create("UICorner")({
					CornerRadius = UDim.new(1, 0),
				}),

				create("UIPadding")({
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 5),
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

				create("TextLabel")({
					Name = "Label",
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 14),
					Text = "",
					TextSize = 11,
					ZIndex = 50,
				}),
			}),
		}),

		create("Frame")({
			Name = "Divider",
			BorderSizePixel = 0,
			LayoutOrder = 1,
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
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			ZIndex = 50,

			create("UIListLayout")({
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
	}) :: Frame

	local body = structures.Body.__instance :: Frame

	structures.Header = body:FindFirstChild("Header") :: Frame
	structures.Icon = structures.Header:FindFirstChild("Icon") :: ImageLabel
	structures.Title = structures.Header:FindFirstChild("Title") :: TextLabel
	structures.Status = structures.Header:FindFirstChild("Status") :: Frame
	structures.StatusDot = structures.Status:FindFirstChild("Dot") :: Frame
	structures.StatusLabel = structures.Status:FindFirstChild("Label") :: TextLabel
	structures.Rows = body:FindFirstChild("Rows") :: Frame

	--// Functions
	local function shown(name: string): boolean
		local only = properties.Only

		return typeof(only) ~= "table" or table.find(only, name) ~= nil
	end

	local function renderRow(name: string)
		local row = rows[name]

		if row then
			local text, rate = store:Format(name)

			row.Value.Text = rate and (text .. '  <font transparency="0.45">' .. rate .. "</font>") or text
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
					ImageColor3 = theme.Controls.SwitchAccent[1],
				},
			}),

			create("TextLabel")({
				Name = "Label",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				Position = UDim2.new(0, 22, 0.5, 0),
				Size = UDim2.new(0.5, -22, 0, 14),
				Text = definition.Label,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 50,

				__dynamicKeys = {
					TextColor3 = theme.Text.Secondary[1],
					TextTransparency = theme.Text.Secondary[2],
				},
			}),

			create("TextLabel")({
				Name = "Value",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(1, 0.5),
				RichText = true,
				Size = UDim2.new(0.5, 0, 0, 16),
				Text = "--",
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 50,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),
		}).__instance :: Frame

		local icon = frame:FindFirstChild("Icon") :: ImageLabel
		local label = frame:FindFirstChild("Label") :: TextLabel

		if definition.Icon then
			icons.Apply(icon, definition.Icon, nil, 14)
		else
			icon.Visible = false
			label.Position = UDim2.new(0, 0, 0.5, 0)
			label.Size = UDim2.new(0.5, 0, 0, 14)
		end

		rows[definition.Name] = { Frame = frame, Value = frame:FindFirstChild("Value") :: TextLabel }
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
			if shown(definition.Name) then
				if rows[definition.Name] then
					rows[definition.Name].Frame.LayoutOrder = index
				else
					makeRow(definition, index)
				end
			end
		end

		local hasRows = next(rows) ~= nil

		body:FindFirstChild("Divider").Visible = hasRows
		structures.Rows.Visible = hasRows
	end

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

	theme.Controls.Status.Info[1]:Connect(paintStatus)

	body.Destroying:Connect(function()
		disconnect()

		if ownsStore then
			store:Destroy()
		end
	end)

	draggable(body, body, function()
		return properties.Draggable
	end)

	--// Component
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = tostring(value or "")
		end,
		Icon = function(value)
			local hasIcon = value ~= nil and icons.Apply(structures.Icon, value, nil, 16)

			structures.Icon.Visible = hasIcon == true

			-- Your logo keeps its colours, glyphs take the accent
			structures.Icon.ImageColor3 = (value ~= nil and not icons.IsGlyph(value)) and Color3.new(1, 1, 1)
				or theme.Controls.SwitchAccent[1].Value

			structures.Title.Position = UDim2.new(0, hasIcon and 24 or 0, 0.5, 0)
			structures.Title.Size = UDim2.new(1, -(90 + (hasIcon and 24 or 0)), 0, 16)
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
	object.Set = function(_, name: string, value)
		store:Set(tostring(name), value)
	end
	object.Get = function(_, name: string)
		return store:Get(tostring(name))
	end
	object.Increment = function(_, name: string, amount: number?)
		store:Increment(tostring(name), amount)
	end
	object.Reset = function(_, name: string?)
		store:Reset(name and tostring(name) or nil)
	end

	binder.Apply(properties, object)
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
