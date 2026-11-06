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

		-- Lines of buttons (see layout): one line normally, more when the labels don't fit
		create("UIListLayout")({
			Name = "UIListLayout",
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, properties.Spacing),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		-- Same divider as Row, so Groupbox / Form separate it from the row above like any other row
		create("Folder")({
			Name = "LayoutIgnore",

			create("Frame")({
				Name = "Divider",
				AnchorPoint = Vector2.new(0, 1),
				BorderSizePixel = 0,
				-- +10: the row's own bottom padding also applies to this divider, which put it right
				-- under the buttons (hidden by them); this moves it to the row's real bottom edge
				Position = UDim2.new(0, 0, 1, 10),
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

	local utility = require("@modules/utility")
	local layoutQueued = false

	local lineFrames = {}

	local function bodyOf(button)
		local body = button.Structures and button.Structures.Body

		if typeof(body) == "table" then
			body = body.__instance
		end

		return typeof(body) == "Instance" and body or nil
	end

	local function labelOf(button)
		local label = button.Structures and button.Structures.Label

		if typeof(label) == "table" then
			label = label.__instance
		end

		return typeof(label) == "Instance" and label or nil
	end

	-- Uses the whole width: as many buttons per line as fit their (unwrapped) labels, the rest
	-- go to the next line, and every line's buttons share that line's full width. Labels never
	-- wrap ("Server / Hop") and no line is left half empty.
	local function layout()
		layoutQueued = false

		local count = #buttons

		if count == 0 then
			return
		end

		local spacing = properties.Spacing
		local body = structures.Body.__instance

		-- queued layouts can run after the UI was unloaded
		if not body.Parent then
			return
		end
		local scale = utility.GetScale(body)
		local available = scale > 0.05 and body.AbsoluteSize.X / scale or 0

		-- Widest label decides how many fit on one line
		local widest = 0

		for _, button in ipairs(buttons) do
			local label = labelOf(button)

			if label then
				label.TextWrapped = false
				label.TextTruncate = Enum.TextTruncate.AtEnd

				local bounds = label.TextBounds.X / (scale > 0.05 and scale or 1)

				widest = math.max(widest, bounds + 28) -- label padding + breathing room
			end
		end

		local columns = count

		if available > 0 and widest > 0 then
			while columns > 1 and columns * widest + (columns - 1) * spacing > available do
				columns -= 1
			end
		end

		local lines = math.ceil(count / columns)
		local perLine = math.ceil(count / lines) -- balance lines: 3 buttons -> 2 + 1 becomes 2 + 1, 4 -> 2 + 2

		-- One frame per line
		for index = #lineFrames + 1, lines do
			lineFrames[index] = create("Frame")({
				Name = "Line",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, properties.Height),
				Parent = body,

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, spacing),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			}).__instance
		end

		for index, button in ipairs(buttons) do
			local line = math.ceil(index / perLine)
			local inLine = math.min(perLine, count - (line - 1) * perLine)
			local instance = bodyOf(button)

			if instance then
				instance.AutomaticSize = Enum.AutomaticSize.None
				instance.LayoutOrder = index
				instance.Size = UDim2.new(1 / inLine, -math.ceil(spacing * (inLine - 1) / inLine), 0, properties.Height)
				instance.Parent = lineFrames[line]
			end
		end

		-- Only now remove lines that are no longer needed (destroying them earlier would destroy
		-- the buttons still inside)
		for index = #lineFrames, lines + 1, -1 do
			lineFrames[index]:Destroy()
			lineFrames[index] = nil
		end
	end

	local function queueLayout()
		if not layoutQueued then
			layoutQueued = true
			task.defer(layout)
		end
	end

	structures.Body.__instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueLayout)

	local object = binder.Wrap(properties, {}, structures.Body)

	object.Type = "ButtonRow"
	object.Theme = self.Theme
	object.Structures = structures
	object.Buttons = buttons

	object.Add = function(_, buttonProperties)
		local button = (context:Button(buttonProperties))

		table.insert(buttons, button)
		layout()

		local label = labelOf(button)

		if label then
			label:GetPropertyChangedSignal("TextBounds"):Connect(queueLayout)
		end

		return button
	end

	for _, buttonProperties in ipairs(initialButtons) do
		object:Add(buttonProperties)
	end

	return object
end
