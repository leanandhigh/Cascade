--[[
	Settings
	Builds a complete Settings tab in one call. Everything is shown directly in the tab:

		Left  "Interface": theme, accent, menu keybind, censor name, hide avatar,
		                   watermark / keybind list toggles, unload
		Right "Configs":   the ConfigManager groupbox

	window:Settings({
		Watermark = watermark,        -- optional, adds a "Show watermark" toggle
		KeybindList = keybinds,       -- optional, adds a "Show keybind list" toggle
		MenuKey = Enum.KeyCode.RightControl,
	})

	Returns the settings tab, add your own groupboxes to it as usual.
]]

local types = require("@types")

return function(self, properties: types.SettingsProperties): types.Tab
	--// Imports
	local services = require("@modules/services")
	local themes = require("@themes/init")
	local accents = require("@themes/accents")

	--// References
	local userInputService = services.UserInputService

	--// Variables
	properties = properties or {}

	local window = self.__window or self
	local app = window.__app

	-- Settings live in their own sidebar group at the bottom, apart from the script's tabs.
	-- Pass Section = false to add the tab directly, or a string to rename the group.
	local holder = self

	if properties.Section ~= false and self.Type == "Window" then
		holder = self:Section({
			Title = typeof(properties.Section) == "string" and properties.Section or "General",
			Disclosure = false,
		})

		holder.LayoutOrder = 100000
	end

	local tab = holder:Tab({
		Title = properties.Title or "Settings",
		Icon = properties.Icon or "settings",
		Selected = properties.Selected == true,
	})

	--// Interface
	local interface = tab:Groupbox({
		Side = "Left",
		Title = "Interface",
		Subtitle = "Look and behaviour of the menu",
		Icon = "palette",
		Collapsible = false,
	})

	if app then
		local themeNames = { "Dark", "Light" }

		interface:Row({ Title = "Theme" }):Right():RadioButtonGroup({
			Flag = properties.ThemeFlag or "UI_Theme",
			Options = themeNames,
			Value = (app.Theme and app.Theme._id == "Light") and 2 or 1,
			ValueChanged = function(_, index: number)
				local theme = themes[themeNames[index]]

				if theme and (not app.Theme or app.Theme._id ~= theme._id) then
					app.Theme = theme
				end
			end,
		})

		local accentNames = {}

		for name in pairs(accents) do
			table.insert(accentNames, name)
		end

		table.sort(accentNames)

		interface:Row({ Title = "Accent" }):Right():PopUpButton({
			Flag = properties.AccentFlag or "UI_Accent",
			Options = accentNames,
			Value = table.find(accentNames, app.Accent and app.Accent._id or "Blue") or 1,
			ValueChanged = function(popup, index: number)
				local accent = accents[popup.Options[index]]

				if accent and (not app.Accent or app.Accent._id ~= accent._id) then
					app.Accent = accent
				end
			end,
		})
	end

	-- Menu keybind (minimize / restore). Ignored only while typing in a TextBox.
	local menuKey = properties.MenuKey or Enum.KeyCode.RightControl

	interface:Row({ Title = "Menu keybind", Subtitle = "Shows / hides the menu" }):Right():KeybindField({
		Flag = properties.MenuKeyFlag or "UI_MenuKey",
		Value = menuKey,
		ValueChanged = function(_, value: Enum.KeyCode)
			menuKey = value
		end,
	})

	local menuConnection = userInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= menuKey or userInputService:GetFocusedTextBox() then
			return
		end

		window.Minimized = not window.Minimized
	end)

	window.Destroying:Connect(function()
		menuConnection:Disconnect()
	end)

	interface:Row({ Title = "Censor name" }):Right():Toggle({
		Value = window.CensorName == true,
		ValueChanged = function(_, value: boolean)
			window.CensorName = value
		end,
	})

	interface:Row({ Title = "Hide avatar" }):Right():Toggle({
		Value = window.HideAvatar == true,
		ValueChanged = function(_, value: boolean)
			window.HideAvatar = value
		end,
	})

	if properties.Watermark then
		interface:Row({ Title = "Show watermark" }):Right():Toggle({
			Flag = "UI_Watermark",
			Value = properties.Watermark.Visible ~= false,
			ValueChanged = function(_, value: boolean)
				properties.Watermark.Visible = value
			end,
		})
	end

	if properties.KeybindList then
		interface:Row({ Title = "Show keybind list" }):Right():Toggle({
			Flag = "UI_KeybindList",
			Value = properties.KeybindList.Visible ~= false,
			ValueChanged = function(_, value: boolean)
				properties.KeybindList.Visible = value
			end,
		})
	end

	if window.Unload then
		interface:Row({ Title = "Unload", Subtitle = "Removes the whole UI" }):Right():Button({
			Label = "Unload",
			State = "Destructive",
			Pushed = function()
				window:Unload()
			end,
		})
	end

	--// Configs
	tab:ConfigManager({
		Side = "Right",
		Manager = window.Configs,
	})

	return tab
end
