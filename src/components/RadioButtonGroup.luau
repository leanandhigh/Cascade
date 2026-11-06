local types = require("@types")

return function(self, properties: types.RadioButtonGroupProperties): types.RadioButtonGroup
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme.Controls.RadioButtonGroup
	local structures = {
		RadioButtons = {},
	}

	--// Functions
	-- Selected: accent fill + white dot. Not selected: control fill + thin outline.
	local function paintRadio(button: Instance, selected: boolean)
		local outline = button:FindFirstChild("Outline")
		local dot = button:FindFirstChild("Dot")

		button.BackgroundColor3 = selected and self.Theme.Controls.Selection[1].Value or theme.Background[1].Value
		button.BackgroundTransparency = selected and self.Theme.Controls.Selection[2].Value or theme.Background[2].Value

		if outline then
			outline.Color = self.Theme.Controls.ViewBorder[1].Value
			outline.Transparency = selected and 1 or math.min(self.Theme.Controls.ViewBorder[2].Value, 0.75)
		end

		if dot then
			dot.Visible = selected
		end
	end

	local function radioButton(object, name, index)
		structures.RadioButtons[index] = create("Frame")({
			Name = "RadioButton",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = structures.Body.__instance,

			create("UIListLayout")({
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			-- Drawn with frames + UICorner + UIStroke (vector), not 14px images: images got
			-- resampled when the UI scale changed and the dots looked uneven / blurry
			create("TextButton")({
				Name = "Button",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(16, 16),
				Text = "",

				create("UICorner")({
					CornerRadius = UDim.new(1, 0),
				}),

				create("UIStroke")({
					Name = "Outline",
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 1,
				}),

				create("Frame")({
					Name = "Dot",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(6, 6),
					Visible = false,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),
				}),
			}),

			create("TextLabel")({
				Name = "Label",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new(require("@modules/fonts").Family),
				LayoutOrder = 1,
				RichText = true,
				Text = name,
				TextSize = 15,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Visible = not not name,

				__dynamicKeys = {
					TextColor3 = self.Theme.Text.Primary[1],
					TextTransparency = self.Theme.Text.Primary[2],
				},
			}),
		}) :: Frame

		local row = structures.RadioButtons[index].__instance or structures.RadioButtons[index]
		local button = row:FindFirstChild("Button") :: TextButton
		local label = row:FindFirstChild("Label") :: TextLabel

		local function choose()
			if object then
				object.Value = index
			end
		end

		button.MouseButton1Click:Connect(choose)

		-- the option name selects it too (bigger target, nicer on phones)
		label.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				choose()
			end
		end)

		paintRadio(button, properties.Value == index)
	end

	--// UI
	properties = properties or {}
	properties.Options = properties.Options or {}

	structures.Body = binder.Apply(
		properties,
		create("Frame")({
			Name = "RadioButtons",
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Parent = parent,

			create("UIListLayout")({
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 16),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Wraps = true,
			}),
		})
	) :: Frame

	--// Initialize
	local object
	local bindings = {
		Options = function(value: { [number]: string })
			for index, option in ipairs(value) do
				if structures.RadioButtons[index] then
					structures.RadioButtons[index]:Destroy()
				end

				radioButton(object, option, index)
			end
		end,
		Value = function(value: number)
			for index, radioButton in ipairs(structures.RadioButtons) do
				local currentIndex = index == value

				if radioButton then
					paintRadio((radioButton.__instance or radioButton):FindFirstChild("Button"), currentIndex)
				end
			end

			if properties.ValueChanged then
				properties.Value = value
				task.spawn(properties.ValueChanged, object, value)
			end
		end,
	}

	object = binder.Wrap(properties, bindings, structures.Body)

	-- Theme / accent changes repaint the circles
	local function repaintAll()
		for index, radio in ipairs(structures.RadioButtons) do
			if radio then
				paintRadio((radio.__instance or radio):FindFirstChild("Button"), properties.Value == index)
			end
		end
	end

	for _, state in ipairs({ self.Theme.Controls.Selection[1], theme.Background[1], self.Theme.Controls.ViewBorder[1] }) do
		state:Connect(function()
			task.defer(repaintAll)
		end)
	end

	object.Type = "RadioButtonGroup"
	object.Theme = self.Theme
	object.Structures = structures
	object.Option = function(self, name: string?)
		local index = #structures.RadioButtons + 1

		radioButton(object, name, index)

		table.insert(properties.Options or {}, name)

		return structures.RadioButtons[index]
	end

	binder.Apply(properties, object)

	return object
end
