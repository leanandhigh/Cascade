--[[
	Cascade — full example

	Shows every feature in one script:
		- Dashboard (update logs + Discord invite)
		- Profile card (censor name / hide avatar / custom options) + key duration
		- Language picker (EN / TH) handled by your own code
		- Config bar (presets, default config for this account or all accounts)
		- Groupboxes side by side, with every control saved through `Flag`
		- Watermark + keybind list overlays
		- Theme / accent settings, minimize keybind, unload button + cleanup

	Loads the build committed on the `claude/friendly-ride-yf5y59` branch (dist/dist.luau).
	Once these features are in a GitHub release you can switch back to the release loader.
]]

--// Import
local CASCADE_URL = "https://raw.githubusercontent.com/leanandhigh/Cascade/claude/friendly-ride-yf5y59/dist/dist.luau"

local source = game:HttpGet(CASCADE_URL)
local chunk, compileError = loadstring(source, "Cascade")
assert(chunk, "Cascade failed to compile: " .. tostring(compileError))

local cascade = chunk()
assert(type(cascade) == "table" and cascade.New, "Cascade did not load, check CASCADE_URL")

--// Services
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")

--// State
local localPlayer = players.LocalPlayer
local connections = {} -- everything here is disconnected on unload
local minimizeKeybind = Enum.KeyCode.RightControl

--// Language
-- Cascade only tells you which language was picked, your script decides the text.
local texts = {
	EN = {
		Main = "Main",
		Farming = "Farming",
		AutoFarm = "Auto Farm",
		AutoFarmInfo = "Automatically farms the selected enemy.",
		Settings = "Settings",
	},
	TH = {
		Main = "หลัก",
		Farming = "ฟาร์ม",
		AutoFarm = "ฟาร์มอัตโนมัติ",
		AutoFarmInfo = "ฟาร์มศัตรูที่เลือกโดยอัตโนมัติ",
		Settings = "ตั้งค่า",
	},
}
local translatable = {} -- { { object, property, key } }

local function t(language: string, key: string): string
	return (texts[language] and texts[language][key]) or texts.EN[key] or key
end

-- Remembers which property of which object shows which text key, so it can be swapped later
local function track(object, property: string, key: string)
	table.insert(translatable, { object, property, key })
	return object
end

local function applyLanguage(language: string)
	for _, entry in ipairs(translatable) do
		local object, property, key = entry[1], entry[2], entry[3]

		pcall(function()
			object[property] = t(language, key)
		end)
	end
end

--// App
local app = cascade.New({
	WindowPill = true, -- tap target to re-open the window on mobile
	Theme = cascade.Themes.Dark,
	Accent = cascade.Accents.Blue,
})

--// Overlays (live on the app, outside of the window)
local watermark = app:Watermark({
	Title = "My Hub",
	Text = "Premium",
	ShowFPS = true,
	ShowPing = true,
	ShowTime = true,
})

local keybinds = app:KeybindList({
	Title = "Keybinds",
	HideInactive = false,
})

--// Window
local window = app:Window({
	Title = "My Hub",
	Subtitle = "Anime Adventures",
	Size = userInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530),

	-- Profile card (bottom-left). The gear opens Censor Name / Hide Avatar + the options below.
	ProfileName = localPlayer.Name,
	CensorName = false,
	ProfileOptions = {
		{
			Title = "Show Watermark",
			Icon = cascade.Symbols.eye,
			Checked = true,
			Changed = function(value: boolean)
				watermark.Visible = value
			end,
		},
		{
			Title = "Show Keybinds",
			Icon = cascade.Symbols.keyboard,
			Checked = true,
			Changed = function(value: boolean)
				keybinds.Visible = value
			end,
		},
		{
			Title = "Copy User Id",
			Icon = cascade.Symbols.docOnDoc,
			Pushed = function()
				if setclipboard then
					setclipboard(tostring(localPlayer.UserId))
				end
			end,
		},
	},
	ProfileSettingChanged = function(self, setting: string, value: boolean)
		print("Profile setting", setting, "=", value)
	end,

	-- Key duration (paid scripts). Use whatever your key system returns:
	--   KeyExpires = 1767225600      -- unix timestamp
	--   KeyDuration = 3 * 86400      -- seconds from now
	--   KeyExpires = "Lifetime"
	KeyExpires = os.time() + 3 * 86400 + 4 * 3600,
	KeyExpired = function(self)
		app:Notification({
			Title = "Key expired",
			Subtitle = "Get a new key to keep using the script.",
			App = "My Hub",
			AppIcon = cascade.Symbols.keyFill,
			Duration = 10,
		})
	end,

	-- Language picker next to the search field
	Languages = { "EN", "TH" },
	Language = "EN",
	LanguageChanged = function(self, language: string)
		applyLanguage(language)
	end,

	-- Config bar in the titlebar. Everything created with `Flag = "..."` is saved.
	Config = {
		Folder = "MyHub",
		SubFolder = tostring(game.PlaceId), -- one set of configs per game
		AutoLoad = true, -- this account's default first, then the all-accounts default
		Ignore = {}, -- flags that should never be saved
		Saved = function(name: string)
			print("Saved config", name)
		end,
		Loaded = function(name: string)
			print("Loaded config", name)
		end,
		Deleted = function(name: string)
			print("Deleted config", name)
		end,
	},

	-- Power button in the titlebar
	CanUnload = true,
	Unloaded = function(self)
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		getgenv().MyHubLoaded = nil
		print("Unloaded")
	end,
})

-- Minimize with a key (Cascade doesn't bind this for you)
table.insert(
	connections,
	userInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if input.KeyCode == minimizeKeybind and not gameProcessedEvent then
			window.Minimized = not window.Minimized
		end
	end)
)

--// Dashboard
local dashboard = window:Dashboard({
	Version = "1.0.16",
	Preview = 5,
	Logs = {
		"+ More maps in Dungeon and Macro settings",
		"~ Card priority could stop the script from loading",
		"+ Improved UI loading on slower devices",
		"+ Save Dungeon path previews by floor",
		"~ Dungeon ignores unwanted maps in current and next-floor paths",
		{ Type = "Removed", Text = "Old macro recorder" },
		{ Type = "Info", Text = "Server maintenance on Friday" },
	},
	LinksTitle = "My Hub \\ Anime Adventures",
	Discord = "https://discord.gg/pGmepY6TC",
	Links = {
		{
			Title = "Website",
			Subtitle = "Click to copy the link.",
			Invite = "https://example.com",
			Icon = cascade.Symbols.globe,
		},
	},
})

-- Logs can be added later too
dashboard:Log("+ Thanks for using My Hub!")

--// Main section
local mainSection = window:Section({
	Title = "Main",
	Disclosure = false,
})
track(mainSection, "Title", "Main")

do -- Farming tab
	local tab = mainSection:Tab({
		Title = "Farming",
		Icon = cascade.Symbols.bolt or cascade.Symbols.sparkles,
	})
	track(tab, "Title", "Farming")

	-- Left groupbox: toggles, slider, keybinds
	local farm = tab:Groupbox({
		Side = "Left",
		Title = "Auto Farm",
		Description = "Farming options",
		Icon = cascade.Symbols.sparkles,
	})

	local autoFarmRow = farm:Row({ Title = "Auto Farm", Subtitle = "Automatically farms the selected enemy." })
	track(autoFarmRow.Structures.TitleStack, "Title", "AutoFarm")
	track(autoFarmRow.Structures.TitleStack, "Subtitle", "AutoFarmInfo")

	local toggleFarmKey -- created below, kept in sync with this toggle

	autoFarmRow:Right():Toggle({
		Flag = "AutoFarm",
		Value = false,
		ValueChanged = function(self, value: boolean)
			print("Auto farm:", value)

			if toggleFarmKey then
				toggleFarmKey.KeybindEntry.Active = value
			end
		end,
	})

	farm:Row({ Title = "Auto Collect" }):Right():Toggle({
		Flag = "AutoCollect",
		Value = true,
	})

	farm:Row({ Title = "Farm Distance" }):Right():Slider({
		Flag = "FarmDistance",
		Minimum = 5,
		Maximum = 50,
		Value = 15,
		ValueChanged = function(self, value: number)
			print("Distance:", value)
		end,
	})

	farm:Row({ Title = "Wave Count" }):Right():Stepper({
		Flag = "WaveCount",
		Minimum = 1,
		Maximum = 50,
		Step = 1,
		Value = 10,
		Fielded = true,
	})

	-- Keybinds linked to the keybind list (it shows the key + whether it's active)
	toggleFarmKey = farm:Row({ Title = "Toggle Farm Key" }):Right():KeybindField({
		Flag = "ToggleFarmKey",
		Value = Enum.KeyCode.F,
		KeybindList = keybinds,
		KeybindName = "Auto Farm",
		KeybindMode = "Toggle",
		BindPressed = function(self, key: Enum.KeyCode, inputComplete: boolean, gameProcessedEvent: boolean)
			if inputComplete or gameProcessedEvent then
				return
			end

			-- The keybind list already flipped its state, mirror it onto the Auto Farm toggle
			cascade.Flags:Set("AutoFarm", self:IsActive())
		end,
	})

	farm:Row({ Title = "Speed Boost (Hold)" }):Right():KeybindField({
		Flag = "SpeedKey",
		Value = Enum.KeyCode.LeftShift,
		KeybindList = keybinds,
		KeybindName = "Speed Boost",
		KeybindMode = "Hold",
	})

	-- Right groupbox: dropdowns, text, buttons
	local target = tab:Groupbox({
		Side = "Right",
		Title = "Target",
		Description = "Who to farm",
		Icon = cascade.Symbols.person,
	})

	target:Row({ Title = "Enemy" }):Right():PopUpButton({
		Flag = "Enemy",
		Options = { "Slime", "Goblin", "Orc", "Dragon" },
		Value = 1,
		ValueChanged = function(self, value: number)
			print("Enemy:", self.Options[value])
		end,
	})

	target:Row({ Title = "Drops", Subtitle = "Pick up to 3" }):Right():PopUpButton({
		Flag = "Drops",
		Options = { "Gold", "Gems", "Items", "Pets" },
		Maximum = 3,
	})

	target:Row({ Title = "Priority" }):Right():RadioButtonGroup({
		Flag = "Priority",
		Options = { "Closest", "Lowest HP" },
		Value = 1,
	})

	target:Row({ Title = "Webhook" }):Right():TextField({
		Flag = "Webhook",
		Placeholder = "https://...",
	})

	local actions = target:Row()
	actions:Right():Button({
		Label = "Teleport",
		State = "Primary",
		Pushed = function()
			print("Teleport!")
		end,
	})
	actions:Right():Button({
		Label = "Reset",
		State = "Destructive",
		Pushed = function()
			cascade.Flags:Set("AutoFarm", false)
			cascade.Flags:Set("FarmDistance", 15)
		end,
	})

	-- Collapsed by default
	tab:Groupbox({
		Side = "Left",
		Title = "Advanced",
		Description = "Click to expand",
		Icon = cascade.Symbols.gearshape,
		Collapsed = true,
	}):Row({ Title = "Debug Prints" }):Right():Toggle({ Flag = "DebugPrints" })

	-- Start the keybind list entry in the same state as the Auto Farm toggle
	toggleFarmKey.KeybindEntry.Active = cascade.Flags:Get("AutoFarm") == true
end

--// Settings section
local settingsSection = window:Section({
	Title = "Settings",
	Disclosure = false,
})
track(settingsSection, "Title", "Settings")

do -- Settings tab
	local tab = settingsSection:Tab({
		Title = "Settings",
		Icon = cascade.Symbols.gearshapeFill,
	})
	track(tab, "Title", "Settings")

	-- Appearance (saved too)
	local appearance = tab:Groupbox({
		Side = "Left",
		Title = "Appearance",
		Icon = cascade.Symbols.paintbrush or cascade.Symbols.sparkles,
	})

	appearance:Row({ Title = "Theme" }):Right():RadioButtonGroup({
		Flag = "UITheme",
		Options = { "Dark", "Light" },
		Value = 1,
		ValueChanged = function(self, value: number)
			app.Theme = cascade.Themes[self.Options[value]]
		end,
	})

	local accents = {}
	for name in pairs(cascade.Accents) do
		table.insert(accents, name)
	end
	table.sort(accents)

	appearance:Row({ Title = "Accent" }):Right():PopUpButton({
		Flag = "UIAccent",
		Options = accents,
		Value = table.find(accents, "Blue"),
		ValueChanged = function(self, value: number)
			app.Accent = cascade.Accents[self.Options[value]]
		end,
	})

	appearance:Row({ Title = "Watermark Text" }):Right():TextField({
		Flag = "WatermarkText",
		Value = "Premium",
		ValueChanged = function(self, value: string)
			watermark.Text = value
		end,
	})

	appearance:Row({ Title = "Hide inactive keybinds" }):Right():Toggle({
		Flag = "HideInactiveKeybinds",
		Value = false,
		ValueChanged = function(self, value: boolean)
			keybinds.HideInactive = value
		end,
	})

	appearance:Row({ Title = "Minimize Key" }):Right():KeybindField({
		Flag = "MinimizeKey",
		Value = minimizeKeybind,
		ValueChanged = function(self, value: Enum.KeyCode)
			minimizeKeybind = value
		end,
	})

	-- Configs from code (the titlebar bar does all of this with clicks too)
	local configs = tab:Groupbox({
		Side = "Right",
		Title = "Configs",
		Description = "Also available from the titlebar",
		Icon = cascade.Symbols.externaldriveFill,
	})

	local configName = "Main"

	configs:Row({ Title = "Config name" }):Right():TextField({
		Value = configName, -- no Flag: this one is not saved
		ValueChanged = function(self, value: string)
			configName = value
		end,
	})

	local saveLoad = configs:Row()
	saveLoad:Right():Button({
		Label = "Save",
		State = "Primary",
		Pushed = function()
			local ok, err = window.Configs:Save(configName)
			print(ok and ("Saved " .. configName) or err)
		end,
	})
	saveLoad:Right():Button({
		Label = "Load",
		State = "Secondary",
		Pushed = function()
			local ok, err = window.Configs:Load(configName)
			print(ok and ("Loaded " .. configName) or err)
		end,
	})

	local defaults = configs:Row({ Title = "Set as default" })
	defaults:Right():Button({
		Label = "This account",
		State = "Secondary",
		Pushed = function()
			window.Configs:SetDefault(configName, "Account")
		end,
	})
	defaults:Right():Button({
		Label = "All accounts",
		State = "Secondary",
		Pushed = function()
			window.Configs:SetDefault(configName, "All")
		end,
	})

	configs:Row({ Title = "Clear defaults" }):Right():Button({
		Label = "Clear",
		State = "Destructive",
		Pushed = function()
			window.Configs:ClearDefault("Account")
			window.Configs:ClearDefault("All")
		end,
	})

	configs:Row({ Title = "Unload UI" }):Right():Button({
		Label = "Unload",
		State = "Destructive",
		Pushed = function()
			window:Unload()
		end,
	})
end

--// Done
getgenv().MyHubLoaded = true

app:Notification({
	Title = "Loaded",
	Subtitle = "Press " .. minimizeKeybind.Name .. " to hide the UI.",
	App = "My Hub",
	AppIcon = cascade.Symbols.checkmarkCircleFill,
	Duration = 6,
})
