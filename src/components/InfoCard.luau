--[[
	InfoCard
	A card that lists information rows, always visible (nothing hidden behind menus).

	tab:InfoCard({
		Title = "Information",
		Icon = "info",
		Items = {
			{ Label = "Version", Value = "1.0.16" },
			{ Label = "Key", Value = function() return window:KeyStatus() end }, -- refreshed every second
		},
	})

	A Value function may return (text) or (text, colorPair) where colorPair is a theme
	colour such as self.Theme.Controls.Status.Added.
]]

local types = require("@types")

return function(self, properties: types.InfoCardProperties): types.InfoCard
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local icons = require("@modules/icons")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local font = "rbxassetid://12187365364"
	local structures = {}
	local rows = {}

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Information"
	properties.Items = properties.Items or {}

	structures.Body = create("Frame")({
		Name = "InfoCard",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = parent,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.View[1],
			BackgroundTransparency = theme.Controls.View[2],
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
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 6),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 36),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("ImageLabel")({
				Name = "Icon",
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(18, 18),
				Visible = false,

				__dynamicKeys = {
					ImageColor3 = theme.Controls.Selection[1],
				},
			}),

			create("TextLabel")({
				Name = "Title",
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new(font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				LayoutOrder = 1,
				Size = UDim2.fromOffset(0, 18),
				TextSize = 14,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),
		}),

		create("Frame")({
			Name = "List",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 0),

			create("UIListLayout")({
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
	}) :: Frame

	--// Initialize
	structures.Header = structures.Body:FindFirstChild("Header") :: Frame
	structures.Icon = structures.Header:FindFirstChild("Icon") :: ImageLabel
	structures.Title = structures.Header:FindFirstChild("Title") :: TextLabel
	structures.List = structures.Body:FindFirstChild("List") :: Frame

	local function renderRow(row)
		local value = row.Item.Value
		local text, color = value, nil

		if typeof(value) == "function" then
			local ok, resultText, resultColor = pcall(value)

			text = ok and resultText or "—"
			color = ok and resultColor or nil
		end

		color = color or theme.Text.Primary

		row.Value.Text = tostring(text == nil and "—" or text)
		row.Value.TextColor3 = color[1].Value
		row.Value.TextTransparency = color[2].Value
	end

	local function addRow(item)
		local frame = create("Frame")({
			Name = "Row",
			BackgroundTransparency = 1,
			LayoutOrder = #rows + 1,
			Size = UDim2.new(1, 0, 0, 26),
			Parent = structures.List,

			create("TextLabel")({
				Name = "Label",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new(font),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(0.45, 0, 0, 18),
				Text = tostring(item.Label or ""),
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Secondary[1],
					TextTransparency = theme.Text.Secondary[2],
				},
			}),

			create("TextLabel")({
				Name = "Value",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new(font, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.55, 0, 0, 18),
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		})

		local row = {
			Item = item,
			Frame = frame,
			Value = frame:FindFirstChild("Value") :: TextLabel,
		}

		table.insert(rows, row)
		renderRow(row)

		return row
	end

	local object
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = value
		end,
		Icon = function(value)
			structures.Icon.Visible = value ~= nil and icons.Apply(structures.Icon, value)
		end,
		Items = function(items)
			for _, row in ipairs(rows) do
				row.Frame:Destroy()
			end

			table.clear(rows)

			for _, item in ipairs(items or {}) do
				addRow(item)
			end
		end,
	}, structures.Body)

	object.Type = "InfoCard"
	object.Theme = self.Theme
	object.Structures = structures

	object.Add = function(_, item)
		addRow(item)
	end
	object.Refresh = function()
		for _, row in ipairs(rows) do
			renderRow(row)
		end
	end

	binder.Apply(properties, object)

	-- Live values (key countdown etc.)
	task.defer(function()
		while structures.Body.Parent do
			object.Refresh()
			task.wait(1)
		end
	end)

	return object
end
