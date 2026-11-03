--[[
	ButtonRow
	A full-width row of buttons that share the width evenly. Use it for groups of actions
	that have no label of their own (a Row with only buttons on the right looks unfinished).

	box:ButtonRow({
		Buttons = {
			{ Label = "Create", State = "Primary", Pushed = function() end },
			{ Label = "Save", State = "Secondary", Pushed = function() end },
			{ Label = "Load", State = "Secondary", Pushed = function() end },
		},
	})
]]

local types = require("@types")

return function(self, properties: types.ButtonRowProperties): types.ButtonRow
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local structures = {}
	local buttons = {}

	--// UI
	properties = properties or {}
	properties.Buttons = properties.Buttons or {}
	properties.Spacing = properties.Spacing or 8
	properties.Height = properties.Height or 28

	-- Captured now: object.Buttons below is written back into `properties`
	local initialButtons = properties.Buttons

	structures.Body = create("Frame")({
		Name = "ButtonRow",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = parent,

		create("UIPadding")({
			PaddingBottom = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
		}),

		create("UIListLayout")({
			Name = "UIListLayout",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, properties.Spacing),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		-- Same divider as Row, so Groupbox / Form separate it from the row above like any other row
		create("Folder")({
			Name = "LayoutIgnore",

			create("Frame")({
				Name = "Divider",
				AnchorPoint = Vector2.new(0, 1),
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
	}) :: Frame

	-- Context whose container is this row, so :Button() lands inside it
	local context = setmetatable({
		Theme = self.Theme,
		__container = structures.Body.__instance,
		__instance = structures.Body.__instance,
		__window = self.__window,
	}, { __index = self })

	local function layout()
		local count = #buttons
		local spacing = properties.Spacing

		for _, button in ipairs(buttons) do
			button.AutomaticSize = Enum.AutomaticSize.None
			button.Size = UDim2.new(1 / count, -math.ceil(spacing * (count - 1) / count), 0, properties.Height)
		end
	end

	local object = binder.Wrap(properties, {}, structures.Body)

	object.Type = "ButtonRow"
	object.Theme = self.Theme
	object.Structures = structures
	object.Buttons = buttons

	object.Add = function(_, buttonProperties)
		local button = (context:Button(buttonProperties))

		table.insert(buttons, button)
		layout()

		return button
	end

	for _, buttonProperties in ipairs(initialButtons) do
		object:Add(buttonProperties)
	end

	return object
end
