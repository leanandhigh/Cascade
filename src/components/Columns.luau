--[[
	Columns
	Lays out its children side by side, eg. two Groupboxes next to each other.

	local columns = tab:Columns({ Count = 2 })
	local left, right = columns:Left(), columns:Right()

	left:Groupbox({ Title = "Groupbox" })
	right:Groupbox({ Title = "Dropdowns" })

	When the space gets narrower than `StackBelow` (default 480, eg. a phone), the columns stack
	on top of each other instead of squeezing. StackBelow = 0 keeps them side by side always.
]]

local types = require("@types")

return function(self, properties: types.ColumnsProperties): types.Columns
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local structures = {
		Columns = {},
	}
	local contexts = {}

	--// UI
	properties = properties or {}
	properties.Count = math.max(1, math.floor(properties.Count or 2))
	properties.Spacing = properties.Spacing or 9
	properties.StackBelow = properties.StackBelow or 480

	structures.Body = create("Frame")({
		Name = "Columns",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = parent,

		create("UIListLayout")({
			Name = "UIListLayout",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, properties.Spacing),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	}) :: Frame

	--// Initialize
	local count = properties.Count
	local spacing = properties.Spacing

	for index = 1, count do
		local column = create("Frame")({
			Name = "Column" .. index,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Size = UDim2.new(1 / count, -math.ceil(spacing * (count - 1) / count), 0, 0),
			Parent = structures.Body.__instance,

			create("UIListLayout")({
				Name = "UIListLayout",
				Padding = UDim.new(0, spacing),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		structures.Columns[index] = column.__instance

		-- Each column is its own context, so components created on it are parented to that column.
		-- Anything not defined here (component constructors, Theme...) falls back to the parent context.
		contexts[index] = setmetatable({
			Type = "Column",
			Theme = self.Theme,
			Structures = { Body = column.__instance },
			__container = column.__instance,
			__instance = column.__instance,
			__window = self.__window,
		}, {
			__index = self,
		})
	end

	--// Responsive: stack when narrow
	local layout = structures.Body:FindFirstChild("UIListLayout") :: UIListLayout
	local stacked = nil

	local function columnSize(isStacked: boolean): UDim2
		if isStacked then
			return UDim2.fromScale(1, 0)
		end

		return UDim2.new(1 / count, -math.ceil(spacing * (count - 1) / count), 0, 0)
	end

	local function updateLayout()
		local scale = require("@modules/utility").GetScale(structures.Body.__instance)
		local width = structures.Body.__instance.AbsoluteSize.X

		if scale < 0.05 or width <= 0 then
			return
		end

		local shouldStack = count > 1 and width / scale < (properties.StackBelow or 0)

		if shouldStack == stacked then
			return
		end

		stacked = shouldStack
		layout.FillDirection = shouldStack and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal

		for _, column in ipairs(structures.Columns) do
			column.Size = columnSize(shouldStack)
		end
	end

	structures.Body.__instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
	task.defer(updateLayout)

	local object = binder.Wrap(properties, {}, structures.Body)

	object.IsStacked = function()
		return stacked == true
	end

	object.Type = "Columns"
	object.Theme = self.Theme
	object.Structures = structures

	object.Column = function(_, index: number)
		return contexts[index]
	end
	object.Left = function()
		return contexts[1]
	end
	object.Right = function()
		return contexts[count]
	end

	return object
end
