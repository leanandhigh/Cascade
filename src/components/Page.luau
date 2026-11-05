local types = require("@types")

return function(self, properties: types.PageProperties)
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")

	--// References
	local create = creator.Create

	--// Variables
	properties = properties or {}

	local structures = {}

	structures.Page = binder.Apply(
		properties,
		create("ScrollingFrame")({
			Name = "ContentList",
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			ClipsDescendants = false,
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			ScrollBarImageTransparency = 0.6,
			ScrollBarThickness = 7,
			Size = UDim2.fromScale(1, 1),

			__dynamicKeys = {
				ScrollBarImageColor3 = self.Theme.Controls.ScrollBar[1],
				ScrollBarImageTransparency = self.Theme.Controls.ScrollBar[2],
			},

			create("UIListLayout")({
				Name = "UIListLayout",
				Padding = UDim.new(0, 9),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			create("UIPadding")({
				Name = "Margins",
				PaddingBottom = UDim.new(0, 17),
				PaddingLeft = UDim.new(0, 17),
				PaddingRight = UDim.new(0, 17),
				PaddingTop = UDim.new(0, 17),
			}),
		})
	) :: ScrollingFrame

	-- Only this page's own children (it used to scan every component ever created, on every
	-- child added: slow on hubs with many features). Batched to once per frame.
	local paddingQueued = false

	local function refreshPadding()
		paddingQueued = false

		local scoped = {}

		local position = {}

		for index, instance in ipairs(structures.Page.__instance:GetChildren()) do
			if instance:IsA("GuiObject") then
				table.insert(scoped, instance)
				position[instance] = index
			end
		end

		-- same order as the list layout: LayoutOrder, then creation order (stable)
		table.sort(scoped, function(a, b)
			if a.LayoutOrder ~= b.LayoutOrder then
				return a.LayoutOrder < b.LayoutOrder
			end

			return position[a] < position[b]
		end)

		for i, child in ipairs(scoped) do
			if child.Name == "PageSection" then
				local prev = scoped[i - 1]
				local padding = child:FindFirstChildOfClass("UIPadding")
				
				if padding then
					if prev and prev.Name ~= "PageSection" then
						padding.PaddingTop = UDim.new(0, 18)
					else
						padding.PaddingTop = UDim.new(0, 0)
					end
				end
			end
		end
	end

	local function queuePadding()
		if not paddingQueued then
			paddingQueued = true
			task.defer(refreshPadding)
		end
	end

	structures.Page.ChildAdded:Connect(queuePadding)
	structures.Page.ChildRemoved:Connect(queuePadding)

	refreshPadding()

	local object = binder.Wrap(properties, {
		Parent = function(p)
			structures.Page.Parent = p
		end,
	}, structures.Page)

	object.Type = "Page"
	object.Theme = self.Theme
	object.Structures = structures
	if self.__window then
		object.__window = self.__window
	end
	object.__container = structures.Page.__instance or structures.Page

	return object
end
