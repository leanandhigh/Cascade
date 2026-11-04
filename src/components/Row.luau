local types = require("@types")

return function(self, properties: types.RowProperties): types.Row
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local structures = {}

	--// UI
	properties = properties or {}

	structures.Body = binder.Apply(
		properties,
		create("Frame")({
			Name = "Row",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0),
			Parent = parent,

			create("Frame")({
				Name = "LeftAccessory",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0, 1),

				create("UIListLayout")({
					Name = "UIListLayout",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Wraps = true,
				}),

				create("UIPadding")({
					Name = "UIPadding",
					PaddingBottom = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
				}),
			}),

			create("Frame")({
				Name = "RightAccessory",
				AnchorPoint = Vector2.new(1, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0, 1),

				create("UIListLayout")({
					Name = "UIListLayout",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Wraps = true,
				}),

				create("UIPadding")({
					Name = "UIPadding",
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 11),
					PaddingTop = UDim.new(0, 10),
				}),
			}),

			create("Folder")({
				Name = "LayoutIgnore",

				create("Frame")({
					Name = "Divider",
					AnchorPoint = Vector2.new(0, 1),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, 1),
					Visible = false,

					__dynamicKeys = {
						BackgroundColor3 = self.Theme.Controls.ViewBorder[1],
						BackgroundTransparency = self.Theme.Controls.ViewBorder[2],
					},
				}),
			}),
		})
	) :: Frame

	--// Initialize
	structures.LeftAccessories = structures.Body:FindFirstChild("LeftAccessory") :: Frame
	structures.RightAccessories = structures.Body:FindFirstChild("RightAccessory") :: Frame

	local utility = require("@modules/utility")
	local stacked = false

	-- AbsoluteSize is in screen pixels; offsets aren't (mobile UIScale), so measure in offset units.
	-- When the controls don't leave room for the label (narrow phone columns), they move onto
	-- their own line under it instead of overlapping.
	local rightLayout = structures.RightAccessories:FindFirstChildOfClass("UIListLayout")
	local rightPadding = structures.RightAccessories:FindFirstChildOfClass("UIPadding")
	local RIGHT_INSET = 11 -- gap between the label and the controls when side by side

	-- Width the controls need (their content + the gap), the same whether stacked or not.
	-- (While stacked the frame itself spans the row, so its AbsoluteSize would keep it stacked.)
	local function naturalRightWidth(scale: number): number
		local ok, content = pcall(function()
			return rightLayout.AbsoluteContentSize
		end)

		if ok and typeof(content) == "Vector2" and content.X > 0 then
			return content.X / scale + RIGHT_INSET
		end

		return structures.RightAccessories.AbsoluteSize.X / scale
	end

	local function updateAccessories()
		local scale = utility.GetScale(structures.Body)

		if scale < 0.05 then
			return
		end

		local parentWidth = structures.LeftAccessories.Parent.AbsoluteSize.X / scale
		local rightWidth = naturalRightWidth(scale)
		local leftHasContent = false

		for _, child in ipairs(structures.LeftAccessories:GetChildren()) do
			if child:IsA("GuiObject") and child.Visible then
				leftHasContent = true
				break
			end
		end

		-- Room the label needs: its title's text width (+ padding), not a fixed 90px, so short
		-- labels ("Priority", "Config") stay beside wide controls instead of stacking
		local minLeftWidth = 90
		local titleLabel = structures.TitleStack and structures.TitleStack.Structures
			and structures.TitleStack.Structures.Title

		if titleLabel then
			local ok, bounds = pcall(function()
				return (typeof(titleLabel) == "Instance" and titleLabel or titleLabel.__instance).TextBounds
			end)

			if ok and typeof(bounds) == "Vector2" and bounds.X > 0 then
				minLeftWidth = math.clamp(math.ceil(bounds.X / scale) + 16, 40, 90)
			end
		end

		-- A slider gives up width first (down to 80) so its label keeps a line of its own;
		-- the row only stacks when that still isn't enough
		local slider = structures.RightAccessories:FindFirstChild("Slider")

		if slider and slider:IsA("GuiObject") and leftHasContent and parentWidth > 0 then
			local base = slider:GetAttribute("BaseWidth")

			if not base then
				base = slider.Size.X.Offset
				slider:SetAttribute("BaseWidth", base)
			end

			local current = slider.Size.X.Offset
			local others = rightWidth - current
			local width = math.clamp(math.floor(parentWidth - others - minLeftWidth), 80, base)

			if width ~= current then
				slider.Size = UDim2.new(slider.Size.X.Scale, width, slider.Size.Y.Scale, slider.Size.Y.Offset)
				return -- AbsoluteSize changes and runs this again with the new width
			end
		end

		stacked = leftHasContent and parentWidth > 0 and parentWidth - rightWidth < minLeftWidth

		if stacked then
			-- Controls go on their own line *under* the label, starting where the text starts
			local leftHeight = structures.LeftAccessories.AbsoluteSize.Y / scale

			structures.LeftAccessories.Size = UDim2.new(1, 0, 0, 0)
			structures.RightAccessories.AnchorPoint = Vector2.new(0, 0)
			structures.RightAccessories.Position = UDim2.new(0, 0, 0, math.max(leftHeight - 10, 0))
			-- full width, no row-height scale (that would feed back into the row's AutomaticSize)
			structures.RightAccessories.Size = UDim2.new(1, 0, 0, 0)

			if rightLayout then
				rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			end

			if rightPadding then
				rightPadding.PaddingLeft = UDim.new(0, 0)
			end
		else
			structures.LeftAccessories.Size = UDim2.new(0, math.max(parentWidth - rightWidth, minLeftWidth), 1, 0)
			structures.RightAccessories.AnchorPoint = Vector2.new(1, 0)
			structures.RightAccessories.Position = UDim2.fromScale(1, 0)
			structures.RightAccessories.Size = UDim2.fromScale(0, 1)

			if rightLayout then
				rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			end

			if rightPadding then
				rightPadding.PaddingLeft = UDim.new(0, RIGHT_INSET)
			end
		end
	end

	updateAccessories()
	structures.RightAccessories:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAccessories)

	if rightLayout then
		rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateAccessories)
	end

	structures.LeftAccessories.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAccessories)
	structures.LeftAccessories:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if stacked then
			updateAccessories()
		end
	end)

	-- Optional built-in TitleStack, created on first use: Row({ Title = "...", Subtitle = "..." })
	local titleStack = nil

	local function getTitleStack()
		if not titleStack then
			titleStack = require("@components/TitleStack")({
				Theme = self.Theme,
				__container = structures.LeftAccessories,
			}, {
				Title = "",
			})

			structures.TitleStack = titleStack

			-- re-check the layout once the title's real width is known (text set, font loaded)
			local title = titleStack.Structures and titleStack.Structures.Title

			if title then
				pcall(function()
					local instance = typeof(title) == "Instance" and title or title.__instance

					instance:GetPropertyChangedSignal("TextBounds"):Connect(updateAccessories)
				end)
			end
		end

		return titleStack
	end

	local object = binder.Wrap(properties, {
		SearchIndex = function(value: string)
			structures.Body:SetAttribute("SearchIndex", value)
		end,
		Title = function(value: string)
			getTitleStack().Title = value

			if properties.SearchIndex == nil then
				structures.Body:SetAttribute("SearchIndex", value)
			end
		end,
		Subtitle = function(value: string)
			getTitleStack().Subtitle = value
		end,
	}, structures.Body)

	object.Type = "Row"
	object.Theme = self.Theme
	object.Structures = structures
	object.Left = function()
		local newObject = table.clone(object)

		newObject.__container = structures.LeftAccessories

		return newObject
	end
	object.Right = function()
		local newObject = table.clone(object)

		newObject.__container = structures.RightAccessories

		return newObject
	end

	binder.Apply(properties, object)

	return object
end
