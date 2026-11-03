--[[
	Cascade — full example

	Shows every feature in one script:
		- Dashboard: information (player, key time, game, executor, version), update logs, Discord
		- Profile card (censor name / hide avatar / custom options) + key duration
		- Language picker (EN / TH) handled by your own code
		- Settings tab with configs (default config for this account or all accounts)
		- Groupboxes side by side, with every control saved through `Flag`
		- Watermark + keybind list overlays
		- Lucide icon names everywhere ("house", "swords"...), unload button + cleanup

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
	Icon = "gem", -- same as the window logo
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
local LOGO = "gem" -- your logo: an asset id (eg. 1234567890 / "rbxassetid://1234567890") or a Lucide icon name

local window = app:Window({
	Title = "My Hub",
	Subtitle = "Anime Adventures",

	-- Branding: logo + name at the top-left of the sidebar
	Logo = LOGO,
	Brand = "My Hub",
	BrandSubtitle = "Premium",

	-- The acrylic blur uses a DepthOfField effect that costs FPS on weaker devices
	UIBlur = false,
	Size = userInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530),

	-- Profile card (bottom-left). The gear opens Censor Name / Hide Avatar + the options below.
	ProfileName = localPlayer.Name,
	CensorName = false,
	ProfileOptions = {
		{
			Title = "Show Watermark",
			Icon = "eye",
			Checked = true,
			Changed = function(value: boolean)
				watermark.Visible = value
			end,
		},
		{
			Title = "Show Keybinds",
			Icon = "keyboard",
			Checked = true,
			Changed = function(value: boolean)
				keybinds.Visible = value
			end,
		},
		{
			Title = "Copy User Id",
			Icon = "copy",
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

	-- Configs: the UI is in the Settings tab (window:Settings). Everything with `Flag = "..."` is saved.
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

--// Dashboard
local dashboard = window:Dashboard({
	Version = "1.0.16",
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
			Icon = "globe",
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
		Icon = "swords", -- Lucide icon names (lucide.dev/icons), Cascade symbols or asset ids
	})
	track(tab, "Title", "Farming")

	-- Left groupbox: toggles, slider, keybinds
	local farm = tab:Groupbox({
		Side = "Left",
		Title = "Auto Farm",
		Description = "Farming options",
		Icon = "sparkles",
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

	local distanceRow = farm:Row({ Title = "Farm Distance" })
	local distanceSlider = distanceRow:Right():Slider({
		Flag = "FarmDistance",
		Minimum = 5,
		Maximum = 50,
		Value = 15,
	})
	local distanceLabel = distanceRow:Right():Label({ Text = "15" }) -- shows the number next to the slider

	distanceSlider.ValueChanged = function(self, value: number)
		value = math.floor(value + 0.5)
		distanceLabel.Text = tostring(value)
	end

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
			-- gameProcessedEvent is ignored on purpose so keys the game also uses still work
			if inputComplete then
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
		Icon = "crosshair",
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
		Icon = "sliders-horizontal",
		Collapsed = true,
	}):Row({ Title = "Debug Prints" }):Right():Toggle({ Flag = "DebugPrints" })

	-- Start the keybind list entry in the same state as the Auto Farm toggle
	toggleFarmKey.KeybindEntry.Active = cascade.Flags:Get("AutoFarm") == true
end

--// Settings tab (one call: theme, accent, menu keybind, censor name, hide avatar,
--// watermark / keybind list toggles, unload, and the full Configs groupbox)
local settingsTab = window:Settings({
	Watermark = watermark,
	KeybindList = keybinds,
	MenuKey = minimizeKeybind, -- saved in configs, change it in the Settings tab
})
track(settingsTab, "Title", "Settings")

--// Done
getgenv().MyHubLoaded = true

app:Notification({
	Title = "Loaded",
	Subtitle = "Press " .. minimizeKeybind.Name .. " to hide the UI.",
	App = "My Hub",
	AppIcon = cascade.Symbols.checkmarkCircleFill,
	Duration = 6,
})
