--[[
	UpdateLog
	A changelog card: header with a count badge, a "View all" toggle, and
	coloured entries.

	tab:UpdateLog({
		Title = "Update Logs",
		Preview = 5,
		Entries = {
			{ Type = "Added", Text = "More maps in Dungeon and Macro settings" },
			{ Type = "Changed", Text = "Card priority could stop the script from loading" },
			"+ Improved UI loading on slower devices", -- shorthand: "+", "~", "-", "!" prefixes
		},
	})
]]

local types = require("@types")

--// Constants
local KINDS = {
	Added = { Glyph = "+", Status = "Added" },
	New = { Glyph = "+", Status = "Added" },
	Improved = { Glyph = "+", Status = "Added" },
	Changed = { Glyph = "~", Status = "Changed" },
	Fixed = { Glyph = "~", Status = "Changed" },
	Removed = { Glyph = "-", Status = "Removed" },
	Info = { Glyph = "!", Status = "Info" },
}

local PREFIXES = {
	["+"] = "Added",
	["~"] = "Changed",
	["-"] = "Removed",
	["!"] = "Info",
}

--// Functions
local function normalize(entry): (string, string)
	if typeof(entry) == "string" then
		local prefix, rest = string.match(entry, "^%s*([%+~%-!])%s*(.*)$")

		if prefix then
			return PREFIXES[prefix], rest
		end

		return "Info", entry
	end

	local kind = entry.Type or entry.Kind or "Added"

	return KINDS[kind] and kind or "Info", entry.Text or entry.Title or ""
end

return function(self, properties: types.UpdateLogProperties): types.UpdateLog
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local symbols = require("@modules/symbols")

	--// References
	local create = creator.Create

	local tweenService = services.TweenService

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local structures = {}
	local items = {}

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Update Logs"
	properties.Preview = properties.Preview or 5
	properties.Expanded = properties.Expanded == true
	properties.Entries = properties.Entries or {}

	structures.Body = create("Frame")({
		Name = "UpdateLog",
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
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 4),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 36),

			create("Frame")({
				Name = "Leading",
				AnchorPoint = Vector2.new(0, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(0, 20),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("TextLabel")({
					Name = "Title",
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Size = UDim2.fromOffset(0, 18),
					TextSize = 14,

					__dynamicKeys = {
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),

				create("TextLabel")({
					Name = "Count",
					AutomaticSize = Enum.AutomaticSize.X,
					BorderSizePixel = 0,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 18),
					Text = "0",
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

					create("UIPadding")({
						PaddingLeft = UDim.new(0, 6),
						PaddingRight = UDim.new(0, 6),
					}),
				}),
			}),

			create("TextButton")({
				Name = "ViewAll",
				AnchorPoint = Vector2.new(1, 0.5),
				AutoButtonColor = false,
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(0, 22),
				Text = "",

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("TextLabel")({
					Name = "Label",
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					Size = UDim2.fromOffset(0, 16),
					Text = "View all",
					TextSize = 12,

					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}),

				create("ImageLabel")({
					ScaleType = Enum.ScaleType.Fit,
					Name = "Chevron",
					BackgroundTransparency = 1,
					Image = symbols.chevronRight,
					LayoutOrder = 1,
					Size = UDim2.fromOffset(10, 10),

					__dynamicKeys = {
						ImageColor3 = theme.Text.Secondary[1],
						ImageTransparency = theme.Text.Secondary[2],
					},
				}),
			}),

			create("Frame")({
				Name = "Divider",
				AnchorPoint = Vector2.new(0, 1),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 1),

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.ViewBorder[1],
					BackgroundTransparency = theme.Controls.ViewBorder[2],
				},
			}),
		}),

		create("Frame")({
			Name = "List",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
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
	structures.Leading = structures.Header:FindFirstChild("Leading") :: Frame
	structures.Title = structures.Leading:FindFirstChild("Title") :: TextLabel
	structures.Count = structures.Leading:FindFirstChild("Count") :: TextLabel
	structures.ViewAll = structures.Header:FindFirstChild("ViewAll") :: TextButton
	structures.ViewAllLabel = structures.ViewAll:FindFirstChild("Label") :: TextLabel
	structures.Chevron = structures.ViewAll:FindFirstChild("Chevron") :: ImageLabel
	structures.List = structures.Body:FindFirstChild("List") :: Frame

	local function refresh()
		local total = #items

		for index, item in ipairs(items) do
			item.Frame.Visible = properties.Expanded or index <= properties.Preview
		end

		structures.Count.Text = tostring(total)
		structures.ViewAll.Visible = total > properties.Preview
		structures.ViewAllLabel.Text = properties.Expanded and "Show less" or "View all"

		tweenService
			:Create(
				structures.Chevron,
				TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
				{ Rotation = properties.Expanded and 90 or 0 }
			)
			:Play()
	end

	local function makeItem(entry)
		local kind, text = normalize(entry)
		local info = KINDS[kind]
		local status = theme.Controls.Status[info.Status]

		local frame = create("TextButton")({
			Name = "Entry",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = #items + 1,
			Size = UDim2.new(1, 0, 0, 32),
			Text = "",
			Parent = structures.List,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Fill[1],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 6),
			}),

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 8),
			}),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("TextLabel")({
				Name = "Badge",
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Size = UDim2.fromOffset(22, 22),
				Text = info.Glyph,
				TextSize = 14,

				__dynamicKeys = {
					BackgroundColor3 = status[1],
					TextColor3 = status[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 5),
				}),
			}),

			create("TextLabel")({
				Name = "Text",
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				LayoutOrder = 1,
				RichText = true,
				Size = UDim2.new(1, -32, 0, 18),
				Text = text,
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),
		})

		frame.BackgroundTransparency = 1
		frame:SetAttribute("SearchIndex", text)

		frame.MouseEnter:Connect(function()
			frame.BackgroundTransparency = theme.Controls.Card.Fill[2].Value
		end)
		frame.MouseLeave:Connect(function()
			frame.BackgroundTransparency = 1
		end)

		local item = { Frame = frame, Type = kind, Text = text }

		table.insert(items, item)

		return item
	end

	local object
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = value
		end,
		Preview = function(value: number)
			properties.Preview = value
			refresh()
		end,
		Expanded = function(value: boolean)
			properties.Expanded = value
			refresh()
		end,
		Entries = function(value)
			for _, item in ipairs(items) do
				item.Frame:Destroy()
			end

			table.clear(items)

			for _, entry in ipairs(value or {}) do
				makeItem(entry)
			end

			refresh()
		end,
	}, structures.Body)

	structures.ViewAll.MouseButton1Click:Connect(function()
		object.Expanded = not properties.Expanded
	end)

	object.Type = "UpdateLog"
	object.Theme = self.Theme
	object.Structures = structures

	object.Add = function(_, entry)
		local item = makeItem(entry)

		table.insert(properties.Entries, entry)
		refresh()

		return item
	end
	object.Clear = function()
		object.Entries = {}
	end

	binder.Apply(properties, object)
	refresh()

	return object
end
