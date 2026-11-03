--[[
	KeybindList
	A draggable overlay listing keybinds and whether they are active.

	local keybinds = app:KeybindList({ Title = "Keybinds" })

	-- Manual entries
	local fly = keybinds:Add({ Name = "Fly", Key = Enum.KeyCode.F, Mode = "Toggle" })
	fly.Active = true

	-- Or link a KeybindField, it keeps the key + active state in sync for you
	row:Right():KeybindField({
		Value = Enum.KeyCode.F,
		KeybindList = keybinds,
		KeybindName = "Fly",
		KeybindMode = "Toggle", -- "Toggle" | "Hold" | "Always"
	})
]]

local types = require("@types")

return function(self, properties: types.KeybindListProperties): types.KeybindList
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local utility = require("@modules/utility")
	local symbols = require("@modules/symbols")
	local draggable = require("@modules/draggable")

	--// References
	local create = creator.Create

	--// Variables
	local theme = self.Theme
	local structures = {}
	local entries = {}
	local object

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Keybinds"
	properties.Draggable = properties.Draggable ~= false
	properties.HideInactive = properties.HideInactive == true
	properties.AnchorPoint = properties.AnchorPoint or Vector2.new(0, 0.5)
	properties.Position = properties.Position or UDim2.new(0, 16, 0.5, 0)

	structures.Body = create("Frame")({
		Name = "KeybindList",
		Active = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(220, 0),
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
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 7),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("ImageLabel")({
				ScaleType = Enum.ScaleType.Fit,
				Name = "Icon",
				BackgroundTransparency = 1,
				Image = symbols.keyboardFill or symbols.keyboard,
				Size = UDim2.fromOffset(16, 16),
				ZIndex = 50,

				__dynamicKeys = {
					ImageColor3 = theme.Controls.Selection[1],
				},
			}),

			create("TextLabel")({
				Name = "Title",
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				LayoutOrder = 1,
				Size = UDim2.fromOffset(0, 16),
				TextSize = 13,
				ZIndex = 50,

				__dynamicKeys = {
					TextColor3 = theme.Text.Primary[1],
					TextTransparency = theme.Text.Primary[2],
				},
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
			Name = "List",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),

			create("UIListLayout")({
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),

		create("TextLabel")({
			Name = "Empty",
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://12187365364"),
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 18),
			Text = "No keybinds",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 50,

			__dynamicKeys = {
				TextColor3 = theme.Text.Tertiary[1],
				TextTransparency = theme.Text.Tertiary[2],
			},
		}),
	}) :: Frame

	--// Initialize
	structures.Header = structures.Body:FindFirstChild("Header") :: Frame
	structures.Title = structures.Header:FindFirstChild("Title") :: TextLabel
	structures.List = structures.Body:FindFirstChild("List") :: Frame
	structures.Empty = structures.Body:FindFirstChild("Empty") :: TextLabel

	require("@modules/icons").Apply(structures.Header:FindFirstChild("Icon"), "keyboard", symbols.keyboardFill or symbols.keyboard, 15)

	local function formatKey(key): string
		if key == nil then
			return "None"
		end

		if typeof(key) == "EnumItem" then
			local name = key.Name

			if name == "MouseButton1" then
				return "MB1"
			elseif name == "MouseButton2" then
				return "MB2"
			elseif name == "MouseButton3" then
				return "MB3"
			end

			return name
		end

		return tostring(key)
	end

	local function refresh()
		local visible = 0

		for _, entry in ipairs(entries) do
			local shown = not properties.HideInactive or entry.Active

			entry.Frame.Visible = shown

			if shown then
				visible += 1
			end
		end

		structures.Empty.Visible = visible == 0
	end

	local function paintEntry(entry)
		local text = entry.Active and theme.Text.Primary or theme.Text.Tertiary

		entry.NameLabel.TextColor3 = text[1].Value
		entry.NameLabel.TextTransparency = text[2].Value
		entry.Dot.BackgroundColor3 = entry.Active and theme.Controls.Selection[1].Value or theme.Text.Tertiary[1].Value
		entry.Dot.BackgroundTransparency = entry.Active and 0 or theme.Text.Tertiary[2].Value
	end

	local function add(entryProperties)
		entryProperties = entryProperties or {}
		entryProperties.Name = entryProperties.Name or "Keybind"
		entryProperties.Mode = entryProperties.Mode or "Toggle"
		entryProperties.Active = entryProperties.Active == true or entryProperties.Mode == "Always"

		local frame = create("Frame")({
			Name = "Entry",
			BackgroundTransparency = 1,
			LayoutOrder = #entries + 1,
			Size = UDim2.new(1, 0, 0, 24),
			Parent = structures.List,

			create("Frame")({
				Name = "Dot",
				AnchorPoint = Vector2.new(0, 0.5),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(6, 6),
				ZIndex = 50,

				create("UICorner")({
					CornerRadius = UDim.new(1, 0),
				}),
			}),

			create("TextLabel")({
				Name = "Name",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				Position = UDim2.new(0, 13, 0.5, 0),
				Size = UDim2.new(1, -80, 0, 16),
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 50,
			}),

			create("Frame")({
				Name = "Trailing",
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(0, 20),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("TextLabel")({
					Name = "Mode",
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					-- 11px regular in the faintest colour looked thin and blurry; 12px medium, secondary colour
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					Size = UDim2.fromOffset(0, 20),
					TextSize = 12,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 50,

					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}),

				create("TextLabel")({
					Name = "Key",
					AutomaticSize = Enum.AutomaticSize.X,
					BorderSizePixel = 0,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 20),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 50,

					__dynamicKeys = {
						BackgroundColor3 = theme.Controls.Card.Hover[1],
						BackgroundTransparency = theme.Controls.Card.Hover[2],
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},

					create("UICorner")({
						CornerRadius = UDim.new(0, 5),
					}),

					-- Single letters ("F") get a square key cap instead of a sliver
					create("UISizeConstraint")({
						MinSize = Vector2.new(22, 20),
					}),

					create("UIPadding")({
						PaddingLeft = UDim.new(0, 7),
						PaddingRight = UDim.new(0, 7),
					}),
				}),
			}),
		})

		local trailing = frame:FindFirstChild("Trailing")
		local nameLabel = frame:FindFirstChild("Name")

		-- The name gets whatever space the mode + key cap leave, so they never overlap
		local function fitName()
			nameLabel.Size = UDim2.new(1, -(13 + trailing.AbsoluteSize.X + 8), 0, 16)
		end

		trailing:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitName)
		fitName()

		-- Tap / click an entry to switch it (phones have no keyboard). Entries linked to a
		-- KeybindField run the same code as pressing the key (entry.Pressed).
		local tapArea = Instance.new("TextButton")
		tapArea.Name = "TapArea"
		tapArea.BackgroundTransparency = 1
		tapArea.Size = UDim2.fromScale(1, 1)
		tapArea.Text = ""
		tapArea.ZIndex = 51
		tapArea.Parent = frame.__instance or frame
		local entry = {
			Frame = frame,
			Dot = frame:FindFirstChild("Dot") :: Frame,
			NameLabel = frame:FindFirstChild("Name") :: TextLabel,
			ModeLabel = trailing:FindFirstChild("Mode") :: TextLabel,
			KeyLabel = trailing:FindFirstChild("Key") :: TextLabel,
			Active = entryProperties.Active,
		}

		local entryObject
		entryObject = binder.Wrap(entryProperties, {
			Name = function(value: string)
				entry.NameLabel.Text = value
			end,
			Key = function(value)
				entry.KeyLabel.Text = formatKey(value)
			end,
			Mode = function(value: string)
				-- "Toggle" / "Hold" / "Always"
				entry.ModeLabel.Text = string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
			end,
			Active = function(value: boolean)
				entry.Active = value == true
				entryProperties.Active = entry.Active
				paintEntry(entry)
				refresh()
			end,
		}, frame)

		entryObject.Type = "KeybindListEntry"

		tapArea.MouseButton1Click:Connect(function()
			local pressed = entryObject.Pressed

			if typeof(pressed) == "function" then
				pressed(entryObject)
			elseif entryProperties.Mode == "Toggle" then
				entryObject.Active = not entry.Active
			end
		end)
		entryObject.Remove = function()
			local index = table.find(entries, entry)

			if index then
				table.remove(entries, index)
			end

			frame:Destroy()
			refresh()
		end
		entryObject.Toggle = function()
			entryObject.Active = not entry.Active
		end

		entry.KeyLabel.Text = formatKey(entryProperties.Key)

		table.insert(entries, entry)
		binder.Apply(entryProperties, entryObject)
		paintEntry(entry)
		refresh()

		return entryObject
	end

	-- Repaint entries when the theme or accent changes
	for _, state in { theme.Text.Primary[1], theme.Text.Tertiary[1], theme.Controls.Selection[1] } do
		state:Connect(function()
			task.defer(function()
				for _, entry in ipairs(entries) do
					paintEntry(entry)
				end
			end)
		end)
	end

	draggable(structures.Body.__instance, structures.Body.__instance, function()
		return properties.Draggable
	end)

	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = value
		end,
		HideInactive = function(value: boolean)
			properties.HideInactive = value
			refresh()
		end,
		Draggable = function(value: boolean)
			-- Handled by the draggable module (don't forward to the legacy Frame.Draggable)
			properties.Draggable = value
		end,
	}, structures.Body)

	object.Type = "KeybindList"
	object.Theme = self.Theme
	object.Structures = structures
	object.Add = function(_, entryProperties)
		return add(entryProperties)
	end
	object.Clear = function()
		for index = #entries, 1, -1 do
			entries[index].Frame:Destroy()
			entries[index] = nil
		end

		refresh()
	end

	binder.Apply(properties, object)
	refresh()

	return object
end
