local types = require("@types")

return function(self, properties: types.PopUpButtonProperties): types.PopUpButton
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local dropdownMenu = require("@modules/dropdownMenu")

	--// References
	local create = creator.Create

	--// Constants
	local MAX_DISPLAY_LENGTH = 30

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme.Controls.MenuButton
	local structures = {
		Options = {},
	}

	--// Private Methods
	local function truncate(text: string): string
		if #text > MAX_DISPLAY_LENGTH then
			return string.sub(text, 1, MAX_DISPLAY_LENGTH) .. "..."
		end

		return text
	end

	local function selectedMap(value)
		local map = {}

		if typeof(value) == "table" then
			for _, optionIndex in ipairs(value) do
				map[optionIndex] = true
			end
		elseif value then
			map[value] = true
		end

		return map
	end

	local function selectedLabels(value)
		local labels = {}
		local map = selectedMap(value)

		for index, option in ipairs(structures.Options) do
			local label = option and option:FindFirstChild("Label")
			if map[index] and label then
				table.insert(labels, label.Text)
			end
		end

		return labels
	end

	-- Options can be names, or tables with an image: { Name = "Slime", Icon = 1234567 }
	-- (Text / Title and Image work too). `Icons` gives images by index or by name instead.
	local optionIcons = {}

	local function parseOption(entry, index: number): (string, any?)
		local name, icon = entry, nil

		if typeof(entry) == "table" then
			name = entry.Name or entry.Text or entry.Title or entry[1] or ""
			icon = entry.Icon or entry.Image
		end

		name = tostring(name)

		local iconMap = properties.Icons or properties.Images

		if icon == nil and typeof(iconMap) == "table" then
			icon = iconMap[index] or iconMap[name]
		end

		return name, icon
	end

	--// UI
	properties = properties or {}
	properties.Maximum = properties.Maximum or 1
	properties.Expanded = properties.Expanded or false
	properties.Options = properties.Options or {}

	structures.Body = binder.Apply(
		properties,
		create("TextButton")({
			Name = "PopUpButton",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Selectable = false,
			Text = "",
			Parent = parent,

			create("UIPadding")({
				Name = "UIPadding",
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 9),
				PaddingRight = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 4),
			}),

			create("UIListLayout")({
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("Frame")({
				Name = "PopUpIndicator",
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Selectable = true,
				Size = UDim2.fromOffset(16, 16),

				__dynamicKeys = {
					BackgroundColor3 = theme.IndicatorBackground[1],
					BackgroundTransparency = theme.IndicatorBackground[2],
				},

				create("UICorner")({
					Name = "UICorner",
					CornerRadius = UDim.new(0, 4),
				}),

				create("ImageLabel")({
					Name = "Indicators",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Image = "rbxassetid://89151647333378",
					Size = UDim2.fromScale(1, 1),

					__dynamicKeys = {
						ImageColor3 = self.Theme.Text.Primary[1],
						ImageTransparency = self.Theme.Text.Primary[2],
					},
				}),
			}),

			-- Image of the selected option (single select), in front of its name
			create("ImageLabel")({
				Name = "SelectedIcon",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = -1,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(18, 18),
				Visible = false,

				create("UICorner")({
					CornerRadius = UDim.new(0, 4),
				}),
			}),

			create("TextLabel")({
				Name = "Label",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364"),
				RichText = true,
				Text = "None",
				TextSize = 15,
				TextTransparency = 0.15,
				TextTruncate = Enum.TextTruncate.AtEnd,

				__dynamicKeys = {
					TextColor3 = self.Theme.Text.Primary[1],
					TextTransparency = self.Theme.Text.Primary[2],
				},
			}),
		})
	) :: TextButton

	--// Initialize
	structures.PopUpIndicator = structures.Body:FindFirstChild("PopUpIndicator") :: Frame
	structures.CurrentTab = structures.Body:FindFirstChild("Label") :: TextLabel
	structures.SelectedIcon = structures.Body:FindFirstChild("SelectedIcon") :: ImageLabel

	local function showSelectedIcon(icon)
		local image = structures.SelectedIcon

		if icon == nil then
			image.Visible = false
			return
		end

		local icons = require("@modules/icons")
		local isGlyph = icons.IsGlyph(icon)

		image.Visible = icons.Apply(image, icon, nil, 16)
		image.ImageColor3 = isGlyph and self.Theme.Text.Primary[1].Value or Color3.new(1, 1, 1)
	end

	local object
	local menu = dropdownMenu.new(self, structures, {
		Name = "PopUpMenu",
		Anchor = properties.Anchor,
		AnchorMode = "SelectedLabel",
		ShowsCheckmarks = true,
		MaxHeight = 239,
		OnSelected = function(target, index)
			if target.Maximum and target.Maximum > 1 then
				local current = target.Value or {}
				if typeof(current) ~= "table" then
					current = current and { current } or {}
				else
					current = table.clone(current)
				end

				local foundIndex = nil
				for currentIndex, value in ipairs(current) do
					if value == index then
						foundIndex = currentIndex
						break
					end
				end

				if foundIndex then
					table.remove(current, foundIndex)
				else
					if #current < target.Maximum then
						table.insert(current, index)
					else
						table.remove(current, 1)
						table.insert(current, index)
					end
				end

				target.Value = current
			else
				target.Expanded = false
				task.wait(0.2)
				target.Value = index
			end
		end,
	})

	local function updateValue(value, fireChanged: boolean)
		local isMulti = object and object.Maximum and object.Maximum > 1

		menu:SetAnchorMode(isMulti and "BelowButton" or "SelectedLabel")
		menu:SetValue(value)

		if isMulti then
			local labels = selectedLabels(value)

			showSelectedIcon(nil)

			if #labels == 0 then
				structures.CurrentTab.Text = "None"
			else
				structures.CurrentTab.Text = truncate(table.concat(labels, ", "))
			end

			menu:SetSelectedMap(selectedMap(value))
		else
			local optionLabel = value and structures.Options[value] and structures.Options[value]:FindFirstChild("Label")

			if not optionLabel then
				structures.CurrentTab.Text = "None"
			else
				structures.CurrentTab.Text = truncate(optionLabel.Text)
			end

			showSelectedIcon(value and optionIcons[value] or nil)

			menu:SetSelectedMap(selectedMap(value))
		end

		if fireChanged and properties.ValueChanged then
			properties.Value = value
			task.spawn(properties.ValueChanged, object, value)
		end
	end

	local bindings = {
		Anchor = function(value)
			menu:SetAnchor(value)
		end,

		Options = function(value: { [number]: string })
			menu:ClearOptions()

			table.clear(optionIcons)

			for index, entry in ipairs(value) do
				local optionName, icon = parseOption(entry, index)

				optionIcons[index] = icon
				menu:AddOption(optionName, index, icon)
			end

			if object then
				updateValue(object.Value, false)
			end
		end,

		Expanded = function(value: boolean)
			menu:SetAnchorMode(object and object.Maximum and object.Maximum > 1 and "BelowButton" or "SelectedLabel")
			menu:SetExpanded(value)
		end,

		Value = function(value)
			updateValue(value, true)
		end,

		Icons = function(value)
			properties.Icons = value

			if object then
				object.Options = object.Options
			end
		end,
	}

	object = binder.Wrap(properties, bindings, structures.Body)

	menu:SetObject(object)

	object.Type = "PopUpButton"
	object.Theme = self.Theme
	object.Structures = structures
	object.Option = function(self, name, icon)
		local index = #structures.Options + 1
		local optionName, parsedIcon = parseOption(name, index)

		optionIcons[index] = icon or parsedIcon

		local option = menu:AddOption(optionName, index, optionIcons[index])

		table.insert(object.Options, name)
		updateValue(object.Value, false)

		return option
	end
	object.Remove = function(self, index: number?)
		if index then
			menu:RemoveOption(index)
			object.Options[index] = nil
			updateValue(object.Value, false)
		end
	end

	binder.Apply(properties, object)
	updateValue(object.Value, false)

	return object
end
