local types = require("@types")

return function(self, properties: types.KeybindFieldProperties): types.KeybindFieldProperties
	--// Imports
	local binder = require("@modules/binder")
	local services = require("@modules/services")

	--// References
	local userInputService = services.UserInputService

	--// Variables
	local structures = require("@structures/TextField")(self)

	--// UI
	properties = properties or {}
	properties.Placeholder = properties.Placeholder or "Press a key"

	--// Initialize
	structures.Field.TextXAlignment = Enum.TextXAlignment.Right
	structures.Field.TextEditable = false
	structures.Body.Parent = self.__container or self.__instance or self
	structures.Body.AutomaticSize = Enum.AutomaticSize.XY
	structures.Body.Size = UDim2.fromOffset(0, 23)
	structures.Field.Size = UDim2.fromOffset(0, 23)
	structures.Corner.CornerRadius = UDim.new(0, 6)

	-- Optional KeybindList link: keeps the list's key + active state in sync
	local listEntry = nil

	if properties.KeybindList and properties.KeybindList.Add then
		listEntry = properties.KeybindList:Add({
			Name = properties.KeybindName or "Keybind",
			Key = properties.Value,
			Mode = properties.KeybindMode or "Toggle",
		})
	end

	local object
	object = binder.Wrap(properties, {
		Placeholder = function(value: string)
			structures.Field.PlaceholderText = value
		end,
		Value = function(value: Enum.KeyCode)
			structures.Field.Text = value.Name

			if listEntry then
				listEntry.Key = value
			end

			if properties.ValueChanged then
				properties.Value = value
				task.spawn(properties.ValueChanged, object, value)
			end
		end,
	}, structures.Body)

	userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if input.KeyCode ~= properties.Value then
			return
		end

		-- Like other hub libraries: only ignore the bind while the player is typing in a TextBox.
		-- Keys the game itself uses (gameProcessedEvent) still toggle the bind.
		local typing = userInputService:GetFocusedTextBox() ~= nil

		if listEntry and not typing and not structures.Field:IsFocused() then
			local mode = properties.KeybindMode or "Toggle"

			if mode == "Toggle" then
				listEntry.Active = not listEntry.Active
			elseif mode == "Hold" then
				listEntry.Active = true
			end
		end

		if properties.BindPressed then
			properties.BindPressed(object, input.KeyCode, false, gameProcessedEvent)
		end
	end)

	userInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if structures.Field:IsFocused() then
			object.Value = input.KeyCode
			structures.Field:ReleaseFocus()
			return
		end

		if listEntry and input.KeyCode == properties.Value and (properties.KeybindMode or "Toggle") == "Hold" then
			listEntry.Active = false
		end

		if input.KeyCode == properties.Value and properties.BindPressed then
			properties.BindPressed(object, input.KeyCode, true, gameProcessedEvent)
		end
	end)

	object.Type = "KeybindField"
	object.KeybindEntry = listEntry
	object.IsActive = function()
		return listEntry ~= nil and listEntry.Active == true
	end
	object.Theme = self.Theme
	object.Structures = structures

	binder.Apply(properties, object)

	return object
end
