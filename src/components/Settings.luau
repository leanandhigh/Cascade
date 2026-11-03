--[[
	Settings
	Builds a complete Settings tab in one call. Everything is shown directly in the tab:

		Left  "Interface": theme, accent, menu keybind, watermark / keybind list toggles,
		                   unload (censor name / hide avatar are on the profile card)
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
		local currentTheme = (app.Theme and app.Theme._id == "Light") and "Light" or "Dark"

		interface:Row({ Title = "Theme" }):Right():RadioButtonGroup({
			Flag = properties.ThemeFlag or "UI_Theme",
			Options = themeNames,
			Value = table.find(themeNames, currentTheme),
			ValueChanged = function(_, index: number)
				local name = themeNames[index]

				if name and themes[name] and name ~= currentTheme then
					currentTheme = name
					app.Theme = themes[name]
				end
			end,
		})

		-- Accent: any colour from a colour picker (applied at most ~10x a second while dragging)
		local customAccent = require("@themes/customAccent")
		local startAccent = app.Accent and app.Accent.Dark and app.Accent.Dark.SwitchAccent
		local pending, applying = nil, false

		local function applyAccent()
			while pending do
				local color = pending
				pending = nil

				if not (app.Accent and app.Accent._id == "Custom#" .. color:ToHex()) then
					app.Accent = customAccent(color)
				end

				task.wait(0.1)
			end

			applying = false
		end

		interface:Row({ Title = "Accent" }):Right():ColorPicker({
			Flag = properties.AccentFlag or "UI_AccentColor",
			Title = "Accent",
			Value = typeof(startAccent) == "Color3" and startAccent or Color3.fromHex("#0A84FF"),
			ValueChanged = function(_, color: Color3)
				if typeof(color) ~= "Color3" then
					return
				end

				pending = color

				if not applying then
					applying = true
					task.spawn(applyAccent)
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

	-- Censor name / hide avatar live in the profile card's settings button, not here

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

	if window.Unload and window.CanUnload ~= false then
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
