--[[
	FarmStats
	A card of stat tiles (icon, label, big value), MTwin style. Values update live.

	local stats = box:FarmStats({
		Title = "Farm stats",
		Subtitle = "This session",
		Columns = 3,                                   -- max columns (narrow windows use fewer)
		Stats = {
			{ Name = "Session", Icon = "timer", Type = "Timer" },
			{ Name = "Wins", Icon = "trophy", Value = 0 },
			{ Name = "Gems", Icon = "gem", Value = 0, Format = "short", PerHour = true },
			{ Name = "Level", Icon = "chart-line", Value = function() return player.Level.Value end },
		},
	})

	stats:Increment("Wins")           -- +1
	stats:Increment("Gems", 250)
	stats:Set("Level", 42)
	stats:Get("Gems")
	stats:Reset()                     -- back to the starting values, timers to 0

	app:FarmHud({ Source = stats })   -- the floating HUD can show the same numbers
]]

local types = require("@types")

--// Constants
local TILE_HEIGHT = 58

return function(self, properties: types.FarmStatsProperties): types.FarmStats
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local icons = require("@modules/icons")
	local Store = require("@modules/statStore")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local tiles = {} -- name -> { Frame, Value, Rate }
	local object

	--// UI
	properties = properties or {}

	local ownsStore = properties.Source == nil
	local store = properties.Source and (properties.Source.Store or properties.Source) or Store.new(properties.Stats)
	local hasHeader = properties.Title ~= nil or properties.Subtitle ~= nil

	local card = require("@structures/CardSection")(self, {
		Name = "FarmStats",
		Title = properties.Title or "",
		Subtitle = properties.Subtitle,
		Collapsible = hasHeader and properties.Collapsible ~= false,
		Collapsed = properties.Collapsed,
		Parent = parent,
	})

	if not hasHeader then
		card.Header.Visible = false
	end

	card.UseGrid({
		CellHeight = TILE_HEIGHT,
		MaxColumns = math.max(1, properties.Columns or 3),
		MinColumnWidth = 150,
	})

	local structures = {
		Body = card.Body,
		Card = card,
		Content = card.Content,
	}

	--// Tiles
	local function renderTile(name: string)
		local tile = tiles[name]

		if not tile then
			return
		end

		local text, rate = store:Format(name)

		tile.Value.Text = text
		tile.Rate.Text = rate or ""
		tile.Rate.Visible = rate ~= nil
	end

	local function makeTile(definition, order: number)
		local frame = create("Frame")({
			Name = "Stat",
			BorderSizePixel = 0,
			LayoutOrder = order,
			Parent = card.Content,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Fill[1],
				BackgroundTransparency = theme.Controls.Card.Fill[2],
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

			create("Frame")({
				Name = "IconTile",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(32, 32),

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.SwitchAccent[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 8),
				}),

				create("ImageLabel")({
					Name = "Icon",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromOffset(16, 16),

					__dynamicKeys = {
						ImageColor3 = theme.Controls.SwitchAccent[1],
					},
				}),
			}),

			create("TextLabel")({
				Name = "Label",
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				Position = UDim2.fromOffset(52, 11),
				Size = UDim2.new(1, -60, 0, 14),
				Text = definition.Label,
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Secondary[1],
					TextTransparency = theme.Text.Secondary[2],
				},
			}),

			create("Frame")({
				Name = "Values",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(52, 28),
				Size = UDim2.new(1, -60, 0, 20),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
				}),

				create("TextLabel")({
					Name = "Value",
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Size = UDim2.fromOffset(0, 20),
					Text = "--",
					TextSize = 17,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),

				create("TextLabel")({
					Name = "Rate",
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 16),
					Text = "",
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Visible = false,

					__dynamicKeys = {
						TextColor3 = theme.Controls.Status.Added[1],
					},
				}),
			}),
		}).__instance :: Frame

		frame:SetAttribute("SearchIndex", definition.Label)

		local iconTile = frame:FindFirstChild("IconTile") :: Frame
		local icon = iconTile:FindFirstChild("Icon") :: ImageLabel

		if definition.Icon then
			icons.Apply(icon, definition.Icon, nil, 16)
		else
			-- No icon: text starts at the left edge
			iconTile.Visible = false
			frame:FindFirstChild("Label").Position = UDim2.fromOffset(12, 11)
			frame:FindFirstChild("Label").Size = UDim2.new(1, -20, 0, 14)
			frame:FindFirstChild("Values").Position = UDim2.fromOffset(12, 28)
			frame:FindFirstChild("Values").Size = UDim2.new(1, -20, 0, 20)
		end

		local values = frame:FindFirstChild("Values")

		tiles[definition.Name] = {
			Frame = frame,
			Value = values:FindFirstChild("Value") :: TextLabel,
			Rate = values:FindFirstChild("Rate") :: TextLabel,
		}

		renderTile(definition.Name)
	end

	local function rebuild()
		for name, tile in pairs(tiles) do
			if not store.ByName[name] then
				tile.Frame:Destroy()
				tiles[name] = nil
			end
		end

		for index, definition in ipairs(store.Stats) do
			if tiles[definition.Name] then
				tiles[definition.Name].Frame.LayoutOrder = index
			else
				makeTile(definition, index)
			end
		end
	end

	rebuild()

	local disconnect = store:OnChanged(function(name)
		if name and not tiles[name] then
			rebuild()
			return
		end

		if name then
			renderTile(name)
		else
			for tileName in pairs(tiles) do
				renderTile(tileName)
			end
		end
	end)

	card.Body.__instance.Destroying:Connect(function()
		disconnect()

		if ownsStore then
			store:Destroy()
		end
	end)

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
	}, card.Body)

	card.OnCollapsed(function(isCollapsed)
		properties.Collapsed = isCollapsed
	end)

	object.Type = "FarmStats"
	object.Theme = theme
	object.Structures = structures
	object.Store = store

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
	object.Define = function(_, definition)
		return store:Define(definition)
	end
	object.Format = function(_, name: string)
		return store:Format(tostring(name))
	end

	binder.Apply(properties, object)

	return object
end
