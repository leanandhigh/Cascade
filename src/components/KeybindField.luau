--[[
	KeybindField
	Click it and press a key to bind. Like Obsidian's key picker, right-click it (long-press on
	mobile) for a menu to pick the mode — Toggle / Hold / Always — or Remove the bind.
	Escape while binding also removes it. A removed bind shows "None".

	With a Flag, the key is saved as `Flag` and the mode as `Flag .. "Mode"`.
]]

local types = require("@types")

--// Constants
local NONE = Enum.KeyCode.Unknown -- "no key bound"
local MODES = { "Toggle", "Hold", "Always" }
local LONG_PRESS = 0.5

return function(self, properties: types.KeybindFieldProperties): types.KeybindField
	--// Imports
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local popover = require("@modules/popover")
	local flags = require("@modules/flags")

	--// References
	local userInputService = services.UserInputService

	--// Variables
	local structures = require("@structures/TextField")(self)
	local menu = nil

	--// UI
	properties = properties or {}
	properties.Placeholder = properties.Placeholder or "Press a key"
	properties.KeybindMode = table.find(MODES, properties.KeybindMode) and properties.KeybindMode or "Toggle"

	--// Initialize
	structures.Field.TextXAlignment = Enum.TextXAlignment.Right
	structures.Field.TextEditable = false
	structures.Body.Parent = self.__container or self.__instance or self
	structures.Body.AutomaticSize = Enum.AutomaticSize.XY
	structures.Body.Size = UDim2.fromOffset(0, 28)
	structures.Field.Size = UDim2.fromOffset(0, 0)
	structures.Corner.CornerRadius = UDim.new(0, 6)

	local function bound(): boolean
		return properties.Value ~= nil and properties.Value ~= NONE
	end

	local function mode(): string
		return properties.KeybindMode or "Toggle"
	end

	-- Optional KeybindList link: keeps the list's key, mode and active state in sync
	local listEntry = nil

	if properties.KeybindList and properties.KeybindList.Add then
		listEntry = properties.KeybindList:Add({
			Name = properties.KeybindName or "Keybind",
			Key = bound() and properties.Value or "None",
			Mode = mode(),
		})
	end

	local object
	object = binder.Wrap(properties, {
		Placeholder = function(value: string)
			structures.Field.PlaceholderText = value
		end,
		Value = function(value: Enum.KeyCode?)
			if value == nil then
				value = NONE
			end

			structures.Field.Text = value == NONE and "None" or value.Name

			if listEntry then
				listEntry.Key = value == NONE and "None" or value
			end

			if properties.ValueChanged then
				properties.Value = value
				task.spawn(properties.ValueChanged, object, value)
			end
		end,
		KeybindMode = function(value: string)
			if not table.find(MODES, value) then
				return
			end

			local previous = properties.KeybindMode

			properties.KeybindMode = value

			if listEntry then
				listEntry.Mode = value

				if value == "Always" then
					listEntry.Active = true
				elseif previous == "Always" or value == "Hold" then
					listEntry.Active = false
				end
			end

			if properties.ModeChanged then
				task.spawn(properties.ModeChanged, object, value)
			end
		end,
	}, structures.Body)

	--// Key handling
	userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if not bound() or input.KeyCode ~= properties.Value then
			return
		end

		-- Only ignored while the player is typing in a TextBox; keys the game also uses still work
		local typing = userInputService:GetFocusedTextBox() ~= nil

		if listEntry and not typing and not structures.Field:IsFocused() then
			if mode() == "Toggle" then
				listEntry.Active = not listEntry.Active
			elseif mode() == "Hold" then
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
			-- Escape while binding removes the bind (like Obsidian)
			object.Value = input.KeyCode == Enum.KeyCode.Escape and NONE or input.KeyCode
			structures.Field:ReleaseFocus()
			return
		end

		if not bound() or input.KeyCode ~= properties.Value then
			return
		end

		if listEntry and mode() == "Hold" then
			listEntry.Active = false
		end

		if properties.BindPressed then
			properties.BindPressed(object, input.KeyCode, true, gameProcessedEvent)
		end
	end)

	-- Tapping the entry in the keybind list (mobile) acts like pressing the key once
	if listEntry then
		listEntry.Pressed = function()
			if mode() == "Toggle" then
				listEntry.Active = not listEntry.Active
			end

			if properties.BindPressed then
				task.spawn(properties.BindPressed, object, properties.Value, false, false)
				task.spawn(properties.BindPressed, object, properties.Value, true, false)
			end
		end

		if mode() == "Always" then
			listEntry.Active = true
		end
	end

	--// Mode / remove menu (right-click, or long-press on touch)
	local function openMenu()
		if not menu then
			menu = popover.new(self, { Name = "KeybindMenu", Width = 150 })

			structures.Body.Destroying:Connect(function()
				menu:Destroy()
			end)
		end

		menu:Clear()

		for _, name in ipairs(MODES) do
			menu:AddItem({
				Title = name,
				Checked = mode() == name,
				Changed = function()
					object.KeybindMode = name
				end,
			})
		end

		menu:AddSeparator()
		menu:AddItem({
			Title = "Remove",
			Icon = "x",
			Destructive = true,
			Pushed = function()
				object.Value = NONE
			end,
		})

		structures.Field:ReleaseFocus()
		menu:Show(structures.Body)
	end

	structures.Field.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			openMenu()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local released = false

			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					released = true
					connection:Disconnect()
				end
			end)

			task.delay(LONG_PRESS, function()
				if not released then
					openMenu()
				end
			end)
		end
	end)

	--// Component
	object.Type = "KeybindField"
	object.KeybindEntry = listEntry
	object.IsActive = function()
		if mode() == "Always" then
			return true
		end

		return listEntry ~= nil and listEntry.Active == true
	end
	object.OpenMenu = function()
		openMenu()
	end
	object.Theme = self.Theme
	object.Structures = structures

	binder.Apply(properties, object)

	-- Save the mode next to the key (Flag .. "Mode")
	if properties.Flag ~= nil then
		flags:Register(tostring(properties.Flag) .. "Mode", {
			Get = function()
				return properties.KeybindMode
			end,
			Set = function(value)
				object.KeybindMode = value
			end,
		})
	end

	return object
end
