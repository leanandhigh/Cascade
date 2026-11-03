--[[
	Columns
	Lays out its children side by side, eg. two Groupboxes next to each other.

	local columns = tab:Columns({ Count = 2 })
	local left, right = columns:Left(), columns:Right()

	left:Groupbox({ Title = "Groupbox" })
	right:Groupbox({ Title = "Dropdowns" })
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

	local object = binder.Wrap(properties, {}, structures.Body)

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
