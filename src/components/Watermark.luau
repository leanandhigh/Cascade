--[[
	Watermark
	A small draggable pill: title | fps | ping | time | custom text.

	local watermark = app:Watermark({
		Title = "Cascade",
		Text = "Premium",       -- optional extra segment
		ShowFPS = true,
		ShowPing = true,
		ShowTime = true,
	})

	watermark.Text = "Farming..."
	watermark.Visible = false
]]

local types = require("@types")

return function(self, properties: types.WatermarkProperties): types.Watermark
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local utility = require("@modules/utility")
	local draggable = require("@modules/draggable")

	--// References
	local create = creator.Create

	local runService = services.RunService
	local players = services.Players
	local stats = services.Stats

	--// Variables
	local theme = self.Theme
	local structures = {}
	local frames = 0
	local elapsed = 0
	local fps = 0

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Cascade"
	properties.ShowFPS = properties.ShowFPS ~= false
	properties.ShowPing = properties.ShowPing ~= false
	properties.ShowTime = properties.ShowTime ~= false
	properties.Draggable = properties.Draggable ~= false
	properties.Position = properties.Position or UDim2.fromOffset(16, 64)

	structures.Body = create("Frame")({
		Name = "Watermark",
		Active = true,
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 30),
		ZIndex = 50,
		Parent = utility.OverlayRoot(self),

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
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 12),
		}),

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		create("Frame")({
			Name = "Accent",
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(4, 14),
			ZIndex = 50,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Selection[1],
			},

			create("UICorner")({
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		create("ImageLabel")({
			Name = "Icon",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(16, 16),
			Visible = false,
			ZIndex = 50,

			__dynamicKeys = {
				ImageColor3 = theme.Controls.Selection[1],
			},
		}),

		create("TextLabel")({
			Name = "Label",
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			LayoutOrder = 2,
			RichText = true,
			Size = UDim2.fromOffset(0, 16),
			TextSize = 13,
			ZIndex = 50,

			__dynamicKeys = {
				TextColor3 = theme.Text.Primary[1],
				TextTransparency = theme.Text.Primary[2],
			},
		}),
	}) :: Frame

	--// Initialize
	structures.Icon = structures.Body:FindFirstChild("Icon") :: ImageLabel
	structures.Label = structures.Body:FindFirstChild("Label") :: TextLabel

	local function escape(text: string): string
		return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
	end

	local function ping(): number?
		local ok, value = pcall(function()
			return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)

		if ok and typeof(value) == "number" then
			return value
		end

		local player = players.LocalPlayer

		ok, value = pcall(function()
			return player:GetNetworkPing() * 2000
		end)

		return ok and value or nil
	end

	local function render()
		local separator = ' <font transparency="0.6">|</font> '
		local segments = { "<b>" .. escape(tostring(properties.Title)) .. "</b>" }

		if properties.Text and properties.Text ~= "" then
			table.insert(segments, escape(tostring(properties.Text)))
		end

		if properties.ShowFPS then
			table.insert(segments, string.format("%d fps", fps))
		end

		if properties.ShowPing then
			local value = ping()

			table.insert(segments, value and string.format("%d ms", math.floor(value + 0.5)) or "-- ms")
		end

		if properties.ShowTime then
			table.insert(segments, os.date("%H:%M:%S"))
		end

		structures.Label.Text = table.concat(segments, separator)
	end

	local connection
	connection = runService.RenderStepped:Connect(function(delta)
		if not structures.Body.Parent then
			connection:Disconnect()
			return
		end

		frames += 1
		elapsed += delta

		if elapsed >= 0.5 then
			fps = math.floor(frames / elapsed + 0.5)
			frames = 0
			elapsed = 0

			if structures.Body.Visible then
				render()
			end
		end
	end)

	draggable(structures.Body.__instance, structures.Body.__instance, function()
		return properties.Draggable
	end)

	local function setter(key: string)
		return function(value)
			properties[key] = value
			render()
		end
	end

	local object = binder.Wrap(properties, {
		Title = setter("Title"),
		Text = setter("Text"),
		ShowFPS = setter("ShowFPS"),
		ShowPing = setter("ShowPing"),
		ShowTime = setter("ShowTime"),
		Draggable = function(value: boolean)
			-- Handled by the draggable module (don't forward to the legacy Frame.Draggable)
			properties.Draggable = value
		end,
		Icon = function(value: string?)
			structures.Icon.Visible = value ~= nil
			structures.Icon.Image = value or ""
		end,
	}, structures.Body)

	object.Type = "Watermark"
	object.Theme = self.Theme
	object.Structures = structures

	binder.Apply(properties, object)
	render()

	return object
end
