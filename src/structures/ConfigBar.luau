--[[
	Config bar shown in the titlebar + its "Presets" panel.

	Titlebar:  [ (disk) Unnamed0          v ]

	Panel:
		( Presets )                 refresh  trash  plus
		[ Search...                       ]  sort
		[ Unnamed0           autoload save load ]
		Default: Unnamed0 (this account)

	Rows:
		- click a row to select it (the titlebar shows the selection)
		- click the name of a row to rename it
		- autoload: set as default for this account / all accounts
		- save: overwrite with the current values
		- load: apply the config
]]

return function(self, manager)
	--// Imports
	local creator = require("@modules/creator")
	local services = require("@modules/services")
	local utility = require("@modules/utility")
	local symbols = require("@modules/symbols")
	local popover = require("@modules/popover")

	--// References
	local create = creator.Create

	local tweenService = services.TweenService
	local userInputService = services.UserInputService
	local workspace = services.Workspace

	--// Variables
	local theme = self.Theme
	local font = "rbxassetid://12187365364"
	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local structures = {
		Entries = {},
	}
	local state = {
		Open = false,
		Token = 0,
		Search = "",
		Descending = false,
		Selected = nil,
	}

	--// Helpers
	local function pointInside(guiObject, x: number, y: number): boolean
		if not guiObject or not guiObject.Parent then
			return false
		end

		local position = guiObject.AbsolutePosition
		local size = guiObject.AbsoluteSize

		return x >= position.X and x <= position.X + size.X and y >= position.Y and y <= position.Y + size.Y
	end

	local function iconButton(name: string, image: string, order: number, size: number?)
		local button = create("ImageButton")({
			Name = name,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.fromOffset(24, 24),

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Hover[1],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 6),
			}),

			create("ImageLabel")({
				ScaleType = Enum.ScaleType.Fit,
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = image,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(size or 15, size or 15),

				__dynamicKeys = {
					ImageColor3 = theme.Text.Secondary[1],
					ImageTransparency = theme.Text.Secondary[2],
				},
			}),
		})

		button.MouseEnter:Connect(function()
			button.BackgroundTransparency = theme.Controls.Card.Hover[2].Value
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundTransparency = 1
		end)

		return button, button:FindFirstChild("Icon")
	end

	--// Titlebar pill
	structures.Body = create("TextButton")({
		Name = "ConfigBar",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Size = UDim2.fromOffset(140, 28),
		Text = "",

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
			PaddingLeft = UDim.new(0, 9),
			PaddingRight = UDim.new(0, 9),
		}),

		create("ImageLabel")({
			ScaleType = Enum.ScaleType.Fit,
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = symbols.externaldriveFill,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(14, 14),

			__dynamicKeys = {
				ImageColor3 = theme.Text.Secondary[1],
				ImageTransparency = theme.Text.Secondary[2],
			},
		}),

		create("TextLabel")({
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new(font, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			Position = UDim2.new(0, 22, 0.5, 0),
			Size = UDim2.new(1, -40, 0, 16),
			Text = "None",
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,

			__dynamicKeys = {
				TextColor3 = theme.Text.Primary[1],
				TextTransparency = theme.Text.Primary[2],
			},
		}),

		create("ImageLabel")({
			ScaleType = Enum.ScaleType.Fit,
			Name = "Chevron",
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Image = symbols.chevronDown,
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(11, 11),

			__dynamicKeys = {
				ImageColor3 = theme.Text.Secondary[1],
				ImageTransparency = theme.Text.Secondary[2],
			},
		}),
	})

	structures.Label = structures.Body:FindFirstChild("Label") :: TextLabel
	structures.Chevron = structures.Body:FindFirstChild("Chevron") :: ImageLabel

	--// Panel
	structures.Container = create("ScreenGui")({
		Name = "ConfigPanel",
		Enabled = false,
		IgnoreGuiInset = true,
		OnTopOfCoreBlur = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 201,
	})

	structures.Panel = create("CanvasGroup")({
		Name = "Panel",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Size = UDim2.fromOffset(300, 0),
		Parent = structures.Container.__instance,

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
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		-- Header
		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),

			create("Frame")({
				Name = "Presets",
				AnchorPoint = Vector2.new(0, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(0, 26),

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Selection[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 7),
				}),

				create("UIPadding")({
					PaddingLeft = UDim.new(0, 9),
					PaddingRight = UDim.new(0, 10),
				}),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("ImageLabel")({
					ScaleType = Enum.ScaleType.Fit,
					Name = "Icon",
					BackgroundTransparency = 1,
					Image = symbols.cloudFill,
					Size = UDim2.fromOffset(15, 15),

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
					Size = UDim2.fromOffset(0, 16),
					Text = "Presets",
					TextSize = 13,

					__dynamicKeys = {
						TextColor3 = theme.Controls.Selection[1],
					},
				}),
			}),

			create("Frame")({
				Name = "Actions",
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(0, 24),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			}),
		}),

		-- Search + sort
		create("Frame")({
			Name = "SearchRow",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 30),

			create("Frame")({
				Name = "Search",
				BorderSizePixel = 0,
				Size = UDim2.new(1, -32, 1, 0),

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

				create("ImageLabel")({
					ScaleType = Enum.ScaleType.Fit,
					Name = "Icon",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Image = symbols.magnifyingglass,
					Position = UDim2.new(0, 9, 0.5, 0),
					Size = UDim2.fromOffset(13, 13),

					__dynamicKeys = {
						ImageColor3 = theme.Text.Secondary[1],
						ImageTransparency = theme.Text.Secondary[2],
					},
				}),

				create("TextBox")({
					Name = "Field",
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					FontFace = Font.new(font),
					PlaceholderText = "Search...",
					Position = UDim2.fromOffset(28, 0),
					Size = UDim2.new(1, -36, 1, 0),
					Text = "",
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						PlaceholderColor3 = theme.Text.Tertiary[1],
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),
			}),
		}),

		-- Config list
		create("ScrollingFrame")({
			Name = "List",
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			LayoutOrder = 2,
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 0, 0),

			__dynamicKeys = {
				ScrollBarImageColor3 = theme.Controls.ScrollBar[1],
				ScrollBarImageTransparency = theme.Controls.ScrollBar[2],
			},

			create("UIListLayout")({
				Name = "UIListLayout",
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			create("UIPadding")({
				PaddingBottom = UDim.new(0, 1),
				PaddingLeft = UDim.new(0, 1),
				PaddingRight = UDim.new(0, 1),
				PaddingTop = UDim.new(0, 1),
			}),
		}),

		-- Footer / status
		create("TextLabel")({
			Name = "Status",
			BackgroundTransparency = 1,
			FontFace = Font.new(font),
			LayoutOrder = 3,
			RichText = true,
			Size = UDim2.new(1, 0, 0, 14),
			Text = "",
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,

			__dynamicKeys = {
				TextColor3 = theme.Text.Secondary[1],
				TextTransparency = theme.Text.Secondary[2],
			},
		}),
	})

	utility.ProtectUI(structures.Container.__instance)

	local panel = structures.Panel.__instance
	local header = panel:FindFirstChild("Header")
	local actions = header:FindFirstChild("Actions")
	local searchRow = panel:FindFirstChild("SearchRow")
	local searchField = searchRow:FindFirstChild("Search"):FindFirstChild("Field") :: TextBox
	local list = panel:FindFirstChild("List") :: ScrollingFrame
	local listLayout = list:FindFirstChild("UIListLayout") :: UIListLayout
	local status = panel:FindFirstChild("Status") :: TextLabel

	structures.SearchField = searchField
	structures.List = list
	structures.Status = status

	local refreshButton = iconButton("Refresh", symbols.arrowClockwise, 1)
	local deleteButton = iconButton("Delete", symbols.trash, 2)
	local addButton = iconButton("Add", symbols.plus, 3)

	refreshButton.Parent = actions
	deleteButton.Parent = actions
	addButton.Parent = actions

	local sortButton = iconButton("Sort", symbols.arrowUpArrowDown, 1, 16)
	sortButton.AnchorPoint = Vector2.new(1, 0.5)
	sortButton.Position = UDim2.fromScale(1, 0.5)
	sortButton.Size = UDim2.fromOffset(28, 28)
	sortButton.Parent = searchRow

	local defaultMenu = popover.new(self, { Name = "ConfigDefaultMenu", Width = 210 })

	--// Logic
	local refresh

	local function setStatus(text: string, color)
		color = color or theme.Text.Secondary
		status.Text = text
		status.TextColor3 = color[1].Value
		status.TextTransparency = color[2].Value
	end

	local function describeDefault()
		local name, scope = manager:GetDefault()

		if name then
			setStatus(
				string.format("Default: <b>%s</b> (%s)", name, scope == "All" and "all accounts" or "this account")
			)
		else
			setStatus("No default config")
		end
	end

	local function updatePill()
		structures.Label.Text = state.Selected or manager.Current or "None"
	end

	local function select(name: string?)
		state.Selected = name
		updatePill()
		refresh()
	end

	local function report(ok: boolean, message: string?, success: string)
		if ok then
			setStatus(success, theme.Controls.Status.Added)
		else
			setStatus(message or "Something went wrong", theme.Controls.Status.Removed)
		end

		task.delay(2.5, function()
			if state.Open then
				describeDefault()
			end
		end)
	end

	local function openDefaultMenu(name: string, anchor)
		local scopes = manager:DefaultScopes(name)

		defaultMenu:Clear()
		defaultMenu:AddItem({
			Title = "Default for this account",
			Icon = symbols.personFill,
			Checked = scopes.Account,
			Changed = function(value: boolean)
				manager:SetDefault(value and name or nil, "Account")
				refresh()
			end,
		})
		defaultMenu:AddItem({
			Title = "Default for all accounts",
			Icon = symbols.globe,
			Checked = scopes.All,
			Changed = function(value: boolean)
				manager:SetDefault(value and name or nil, "All")
				refresh()
			end,
		})
		defaultMenu:Show(anchor)
	end

	local function makeEntry(name: string, order: number)
		local isSelected = name == state.Selected
		local scopes = manager:DefaultScopes(name)
		local isDefault = scopes.Account or scopes.All

		local entry = create("TextButton")({
			Name = "Entry",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			Parent = list,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Fill[1],
				BackgroundTransparency = theme.Controls.Card.Fill[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 7),
			}),

			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = isSelected and theme.Controls.Selection[1].Value or theme.Controls.ViewBorder[1].Value,
				Transparency = isSelected and 0 or theme.Controls.ViewBorder[2].Value,
				Thickness = isSelected and 1.5 or 1,
			}),

			create("TextBox")({
				Name = "Name",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				ClearTextOnFocus = false,
				FontFace = Font.new(font, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.new(1, -100, 0, 18),
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
				Name = "Actions",
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -5, 0.5, 0),
				Size = UDim2.fromOffset(0, 24),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			}),
		})

		local nameField = entry:FindFirstChild("Name") :: TextBox
		local entryActions = entry:FindFirstChild("Actions")

		local autoload, autoloadIcon = iconButton("Autoload", symbols.arrowTriangle2Circlepath, 1)
		local save = iconButton("Save", symbols.squareAndArrowDownFill, 2)
		local load = iconButton("Load", symbols.arrowDownCircleFill, 3)

		autoload.Parent = entryActions
		save.Parent = entryActions
		load.Parent = entryActions

		-- Autoload icon is coloured when this config is a default (accent = this account, green = all accounts)
		if isDefault then
			local color = scopes.Account and theme.Controls.Selection or theme.Controls.Status.Added

			autoloadIcon.ImageColor3 = color[1].Value
			autoloadIcon.ImageTransparency = 0
		end

		entry.MouseButton1Click:Connect(function()
			select(name)
		end)

		nameField.Focused:Connect(function()
			if state.Selected ~= name then
				state.Selected = name
				updatePill()
			end
		end)

		nameField.FocusLost:Connect(function()
			local newName = nameField.Text

			if newName == name then
				return
			end

			local ok, message = manager:Rename(name, newName)

			if ok then
				local sanitized = manager:Sanitize(newName)

				if state.Selected == name then
					state.Selected = sanitized
				end

				updatePill()
				refresh()
				report(true, nil, "Renamed to " .. tostring(sanitized))
			else
				nameField.Text = name
				report(false, message, "")
			end
		end)

		autoload.MouseButton1Click:Connect(function()
			openDefaultMenu(name, autoload)
		end)

		save.MouseButton1Click:Connect(function()
			local ok, message = manager:Save(name)

			select(name)
			report(ok, message, "Saved " .. name)
		end)

		load.MouseButton1Click:Connect(function()
			local ok, message = manager:Load(name)

			select(name)
			report(ok, message, "Loaded " .. name)
		end)

		table.insert(structures.Entries, entry)
	end

	refresh = function()
		for _, entry in ipairs(structures.Entries) do
			entry:Destroy()
		end

		table.clear(structures.Entries)

		local names = manager:List()
		local query = string.lower(state.Search)
		local order = 0

		if state.Selected and not table.find(names, state.Selected) then
			state.Selected = nil
			updatePill()
		end

		if state.Descending then
			table.sort(names, function(a, b)
				return string.lower(a) > string.lower(b)
			end)
		end

		for _, name in ipairs(names) do
			if query == "" or string.find(string.lower(name), query, 1, true) then
				order += 1
				makeEntry(name, order)
			end
		end

		if order == 0 then
			setStatus(#names == 0 and "No configs yet, press + to create one" or "No configs match your search")
		else
			describeDefault()
		end
	end

	local function resizeList()
		list.Size = UDim2.new(1, 0, 0, math.min(listLayout.AbsoluteContentSize.Y + 2, 200))
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeList)

	local function position()
		local anchor = structures.Body.__instance
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local size = panel.AbsoluteSize

		local x = anchor.AbsolutePosition.X + anchor.AbsoluteSize.X - size.X
		local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 6

		x = math.clamp(x, 6, math.max(6, viewport.X - size.X - 6))
		y = math.clamp(y, 6, math.max(6, viewport.Y - size.Y - 6))

		panel.Position = UDim2.fromOffset(x, y)
	end

	local function setOpen(open: boolean)
		if state.Open == open then
			return
		end

		state.Open = open
		state.Token += 1

		local token = state.Token

		if open then
			refresh()
			structures.Container.Enabled = true
			position()
			task.defer(position)
		else
			defaultMenu:Close()
		end

		tweenService:Create(structures.Chevron, tweenInfo, { Rotation = open and 180 or 0 }):Play()

		local tween = tweenService:Create(panel, tweenInfo, { GroupTransparency = open and 0 or 1 })

		tween.Completed:Connect(function()
			if not open and token == state.Token then
				structures.Container.Enabled = false
			end
		end)
		tween:Play()
	end

	structures.Body.MouseButton1Click:Connect(function()
		setOpen(not state.Open)
	end)

	structures.Body:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		if state.Open then
			position()
		end
	end)

	userInputService.InputBegan:Connect(function(input)
		if not state.Open then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local x, y = input.Position.X, input.Position.Y

		if
			pointInside(panel, x, y)
			or pointInside(structures.Body.__instance, x, y)
			or (defaultMenu.Open and pointInside(defaultMenu.Group.__instance, x, y))
		then
			return
		end

		setOpen(false)
	end)

	searchField:GetPropertyChangedSignal("Text"):Connect(function()
		state.Search = searchField.Text
		refresh()
	end)

	sortButton.MouseButton1Click:Connect(function()
		state.Descending = not state.Descending
		refresh()
	end)

	refreshButton.MouseButton1Click:Connect(function()
		refresh()
		report(true, nil, "Refreshed")
	end)

	addButton.MouseButton1Click:Connect(function()
		local name = manager:NextName("Unnamed")
		local ok, message = manager:Save(name)

		select(name)
		report(ok, message, "Created " .. name)
	end)

	deleteButton.MouseButton1Click:Connect(function()
		local name = state.Selected

		if not name then
			report(false, "Select a config to delete", "")
			return
		end

		local ok = manager:Delete(name)

		state.Selected = nil
		updatePill()
		refresh()
		report(ok, "Could not delete " .. name, "Deleted " .. name)
	end)

	--// API
	structures.Refresh = function()
		updatePill()

		if state.Open then
			refresh()
		end
	end
	structures.Select = select
	structures.SetOpen = setOpen
	structures.Destroy = function()
		defaultMenu:Destroy()
		structures.Container:Destroy()
	end

	resizeList()
	updatePill()

	return structures
end
