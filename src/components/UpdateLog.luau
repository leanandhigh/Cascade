--[[
	UpdateLog
	A changelog card (MTwin style): title + subtitle header with a count pill and collapse
	chevron, then one card per entry with a tinted icon badge and a type tag.

	tab:UpdateLog({
		Title = "What's new",
		Subtitle = "Version 1.0.16",
		Preview = 5,          -- optional: show 5, the rest behind "View all"
		Collapsed = false,    -- start closed (click the header)
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
	-- Icon = Lucide name (centred image); Glyph = text shown only when the icon isn't available
	Added = { Glyph = "+", Icon = "plus", Status = "Added" },
	New = { Glyph = "+", Icon = "plus", Status = "Added" },
	Improved = { Glyph = "+", Icon = "plus", Status = "Added" },
	Changed = { Glyph = "~", Icon = "refresh-cw", Status = "Changed" },
	Fixed = { Glyph = "~", Icon = "wrench", Status = "Changed" },
	Removed = { Glyph = "-", Icon = "minus", Status = "Removed" },
	Info = { Glyph = "!", Icon = "info", Status = "Info" },
	Note = { Glyph = "!", Icon = "info", Status = "Info" },
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
	local icons = require("@modules/icons")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local items = {}

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Update log"
	properties.Preview = properties.Preview or math.huge
	properties.Expanded = properties.Expanded == true
	properties.Entries = properties.Entries or {}

	local card = require("@structures/CardSection")(self, {
		Name = "UpdateLog",
		Title = properties.Title,
		Subtitle = properties.Subtitle,
		Collapsible = properties.Collapsible ~= false,
		Collapsed = properties.Collapsed,
		Parent = parent,
	})

	local structures = {
		Body = card.Body,
		Card = card,
		Title = card.Title,
		Subtitle = card.Subtitle,
	}

	-- Count pill in the header
	structures.Count = create("TextLabel")({
		Name = "Count",
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Size = UDim2.fromOffset(0, 20),
		Text = "0",
		TextSize = 12,
		Parent = card.Trailing,

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
			PaddingLeft = UDim.new(0, 7),
			PaddingRight = UDim.new(0, 7),
		}),
	}).__instance :: TextLabel

	require("@modules/utility").FitText(structures.Count, 7, 20)

	create("UIListLayout")({
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = card.Content,
	})

	structures.List = card.Content

	-- "View all" footer (only when Preview hides entries)
	structures.ViewAll = create("TextButton")({
		Name = "ViewAll",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		LayoutOrder = 1000000,
		Size = UDim2.new(1, 0, 0, 30),
		Text = "View all",
		TextSize = 12,
		Parent = card.Content,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.Card.Fill[1],
			BackgroundTransparency = theme.Controls.Card.Fill[2],
			TextColor3 = theme.Text.Secondary[1],
			TextTransparency = theme.Text.Secondary[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 7),
		}),
	}).__instance :: TextButton

	structures.ViewAllLabel = structures.ViewAll

	local function refresh()
		local total = #items

		for index, item in ipairs(items) do
			item.Frame.Visible = properties.Expanded or index <= properties.Preview
		end

		structures.Count.Text = tostring(total)
		structures.ViewAll.Visible = total > properties.Preview
		structures.ViewAll.Text = properties.Expanded and "Show less" or ("View all (" .. total .. ")")
	end

	local function makeItem(entry)
		local kind, text = normalize(entry)
		local info = KINDS[kind]
		local status = theme.Controls.Status[info.Status]
		local tagText = typeof(entry) == "table" and entry.Tag or kind

		local frame = create("Frame")({
			Name = "Entry",
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			LayoutOrder = #items + 1,
			Size = UDim2.new(1, 0, 0, 38),
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

			create("UIPadding")({
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 8),
			}),

			create("Frame")({
				Name = "Badge",
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(22, 22),

				__dynamicKeys = {
					BackgroundColor3 = status[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 6),
				}),

				create("ImageLabel")({
					Name = "Icon",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromOffset(12, 12),

					__dynamicKeys = {
						ImageColor3 = status[1],
					},
				}),

				create("TextLabel")({
					Name = "Glyph",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					Text = info.Glyph,
					TextSize = 14,

					__dynamicKeys = {
						TextColor3 = status[1],
					},
				}),
			}),

			create("TextLabel")({
				Name = "Text",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				Position = UDim2.fromOffset(32, 3),
				RichText = true,
				Size = UDim2.new(1, -(32 + 66), 0, 16),
				Text = text,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
			}),

			create("TextLabel")({
				Name = "Tag",
				AnchorPoint = Vector2.new(1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Position = UDim2.new(1, 0, 0, 1),
				Size = UDim2.fromOffset(0, 20),
				Text = tostring(tagText),
				TextSize = 12,

				__dynamicKeys = {
					BackgroundColor3 = status[1],
					TextColor3 = status[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 5),
				}),

				create("UIPadding")({
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),
			}),
		}).__instance :: Frame

		frame:SetAttribute("SearchIndex", text)
		require("@modules/utility").FitText(frame:FindFirstChild("Tag"), 7, 20)

		-- Lucide icon when available (also once it finishes loading), text glyph otherwise
		local badge = frame:FindFirstChild("Badge")
		local badgeIcon = badge:FindFirstChild("Icon") :: ImageLabel
		local badgeGlyph = badge:FindFirstChild("Glyph") :: TextLabel

		local function syncBadge()
			local hasIcon = badgeIcon.Image ~= ""

			badgeIcon.Visible = hasIcon
			badgeGlyph.Visible = not hasIcon
		end

		icons.Apply(badgeIcon, info.Icon, nil, 12)
		syncBadge()
		badgeIcon:GetPropertyChangedSignal("Image"):Connect(syncBadge)

		local item = { Frame = frame, Type = kind, Text = text }

		table.insert(items, item)

		return item
	end

	local object
	object = binder.Wrap(properties, {
		Title = function(value: string)
			card.SetTitle(value)
		end,
		Subtitle = function(value: string?)
			card.SetSubtitle(value)
		end,
		Collapsed = function(value: boolean)
			card.SetCollapsed(value == true)
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
	}, card.Body)

	structures.ViewAll.MouseButton1Click:Connect(function()
		object.Expanded = not properties.Expanded
	end)

	card.OnCollapsed(function(isCollapsed)
		properties.Collapsed = isCollapsed
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
