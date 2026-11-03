--[[
	Cascade — full example

	Layout of this file (same idea as Obsidian's Example.lua):
		1. Load Cascade
		2. Create the app, overlays and window (branding, profile card, key time, language, configs)
		3. Build the UI: tabs, groupboxes and elements — every element is commented
		4. Hook up your logic with cascade.Flags:OnChanged (UI code and logic code stay separate)

	Icons: every `Icon = ...` accepts a Lucide name ("house", "swords" — see https://lucide.dev/icons),
	a Cascade symbol (cascade.Symbols.gearshapeFill) or an image asset id (1234567890).

	Loads the build committed on the `claude/friendly-ride-yf5y59` branch (dist/dist.luau).
]]

--// 1. Load Cascade
local CASCADE_URL = "https://raw.githubusercontent.com/leanandhigh/Cascade/claude/friendly-ride-yf5y59/dist/dist.luau"

local source = game:HttpGet(CASCADE_URL)
local chunk, compileError = loadstring(source, "Cascade")
assert(chunk, "Cascade failed to compile: " .. tostring(compileError))

local cascade = chunk()
assert(type(cascade) == "table" and cascade.New, "Cascade did not load, check CASCADE_URL")

local Flags = cascade.Flags -- every element created with `Flag = "Name"` lives here

--// Services
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")

local localPlayer = players.LocalPlayer
local connections = {} -- your own connections, disconnected on unload

--// Language
-- Cascade only reports which language was picked (LanguageChanged); your script decides the text.
local texts = {
	EN = { Main = "Main", Farming = "Farming", AutoFarm = "Auto Farm", AutoFarmInfo = "Automatically farms the selected enemy.", Settings = "Settings" },
	TH = { Main = "หลัก", Farming = "ฟาร์ม", AutoFarm = "ฟาร์มอัตโนมัติ", AutoFarmInfo = "ฟาร์มศัตรูที่เลือกโดยอัตโนมัติ", Settings = "ตั้งค่า" },
}
local translatable = {} -- { object, property, text key }

-- Remember which property of which object shows which text, so it can be swapped later
local function track(object, property: string, key: string)
	table.insert(translatable, { object, property, key })
	return object
end

local function applyLanguage(language: string)
	for _, entry in ipairs(translatable) do
		pcall(function()
			entry[1][entry[2]] = (texts[language] or texts.EN)[entry[3]] or texts.EN[entry[3]]
		end)
	end
end

--// Branding
-- Your logo's Image asset id (not the Decal id). Left at 0, the game's own icon is used.
local LOGO_ID = 0
local LOGO = LOGO_ID ~= 0 and LOGO_ID or ("rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150")

--// 2. App, overlays and window
local app = cascade.New({
	WindowPill = true, -- small pill at the top of the screen to re-open the window (mobile)
	Theme = cascade.Themes.Dark, -- Dark / Light (changeable in the Settings tab)
	Accent = cascade.Accents.Blue, -- see cascade.Accents (changeable in the Settings tab)
})

-- Watermark: draggable pill with your logo, FPS, ping and time
local watermark = app:Watermark({
	Title = "My Hub",
	Icon = LOGO,
	Text = "Premium", -- any extra text, change it later with watermark.Text = "..."
})

-- Keybind list: shows every KeybindField linked to it and whether it's on
local keybinds = app:KeybindList({
	Title = "Keybinds",
})

local window = app:Window({
	Title = "My Hub",
	Subtitle = "Anime Adventures", -- shown under the page title in the titlebar
	Size = userInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530),
	UIBlur = false, -- the acrylic blur costs FPS on weaker devices

	-- Phones / tablets are detected automatically: 0.8 scale, window fitted to the screen, and a
	-- round draggable button with the logo that shows / hides the window (tap = toggle, drag = move).
	-- MobileToggleSide = "Left",   -- default "Right"
	-- MobileToggle = true,         -- also show the round button on PC

	-- Branding (top-left of the sidebar). With a brand set, the titlebar shows the current tab.
	Logo = LOGO,
	Brand = "My Hub",
	BrandSubtitle = "Premium",

	-- Profile card (bottom-left). Its gear button has Censor Name / Hide Avatar.
	ProfileName = localPlayer.Name,

	-- Key time for paid scripts, shown on the profile card and the Dashboard:
	--   KeyExpires = 1767225600   -- unix timestamp from your key system
	--   KeyDuration = 3 * 86400   -- or seconds from now
	--   KeyExpires = "Lifetime"
	KeyExpires = os.time() + 3 * 86400 + 4 * 3600,
	KeyExpired = function()
		app:Notification({ Title = "Key expired", Subtitle = "Get a new key to keep using the script.", App = "My Hub", Duration = 10 })
	end,

	-- Language picker next to the search field
	Languages = { "EN", "TH" },
	Language = "EN",
	LanguageChanged = function(_, language: string)
		applyLanguage(language)
	end,

	-- Configs. The UI is in the Settings tab; everything created with `Flag = "..."` is saved.
	Config = {
		Folder = "MyHub",
		SubFolder = tostring(game.PlaceId), -- one set of configs per game
		AutoLoad = true, -- loads this account's auto-load config, else the all-accounts one
	},

	-- The titlebar's right button minimizes; Unload (Settings tab) removes the UI — clean up here
	Unloaded = function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		getgenv().MyHubLoaded = nil
	end,
})

--// 3. UI

-- Dashboard: Information (player, key time, game, executor, version), update logs, links
local dashboard = window:Dashboard({
	Version = "1.0.16",
	Logs = {
		-- "+" added, "~" changed / fixed, "-" removed, "!" info
		"+ More maps in Dungeon and Macro settings",
		"~ Card priority could stop the script from loading",
		"+ Improved UI loading on slower devices",
		"+ Save Dungeon path previews by floor",
		"~ Dungeon ignores unwanted maps in current and next-floor paths",
		{ Type = "Removed", Text = "Old macro recorder" }, -- table form works too
	},
	LinksTitle = "My Hub \\ Anime Adventures",
	Discord = "https://discord.gg/pGmepY6TC", -- click to copy
})

dashboard:Log("+ Thanks for using My Hub!") -- add log entries at any time

-- Sections group tabs in the sidebar
local mainSection = window:Section({ Title = "Main", Disclosure = false })
track(mainSection, "Title", "Main")

local farmingTab = mainSection:Tab({
	Title = "Farming",
	Icon = "swords",
})
track(farmingTab, "Title", "Farming")

-- Groupbox: titled box. Side = "Left" / "Right" puts boxes in two columns.
local farmBox = farmingTab:Groupbox({
	Side = "Left",
	Title = "Auto Farm",
	Description = "Farming options",
	Icon = "sparkles",
	-- Collapsed = true,      -- start closed
	-- Collapsible = false,   -- header can't be clicked
})

-- Row: a label on the left (Title / Subtitle), controls on the right via :Right()
local autoFarmRow = farmBox:Row({ Title = "Auto Farm", Subtitle = "Automatically farms the selected enemy." })
track(autoFarmRow.Structures.TitleStack, "Title", "AutoFarm")
track(autoFarmRow.Structures.TitleStack, "Subtitle", "AutoFarmInfo")

-- Toggle
--   Flag:  name for configs / Flags:Get / Flags:OnChanged
--   Value: starting state
autoFarmRow:Right():Toggle({ Flag = "AutoFarm", Value = false })

farmBox:Row({ Title = "Auto Collect" }):Right():Toggle({ Flag = "AutoCollect", Value = true })

-- Slider (Minimum, Maximum, Value). A Label next to it shows the number (updated in the logic section).
local distanceRow = farmBox:Row({ Title = "Farm Distance" })
distanceRow:Right():Slider({ Flag = "FarmDistance", Minimum = 5, Maximum = 50, Value = 15 })
local distanceLabel = distanceRow:Right():Label({ Text = "15" })

-- Stepper (Minimum, Maximum, Step, Value, Fielded = typeable)
farmBox:Row({ Title = "Wave Count" }):Right():Stepper({ Flag = "WaveCount", Minimum = 1, Maximum = 50, Step = 1, Value = 10, Fielded = true })

-- KeybindField
--   Click it and press a key to bind (Escape = no key).
--   Right-click it (long-press on mobile) to pick the mode — Toggle / Hold / Always — or Remove the bind.
--   KeybindList / KeybindName / KeybindMode show it in the keybind list.
--   With a Flag, configs save the key (Flag) and the mode (Flag .. "Mode").
--   Works even when the game also uses the key; ignored only while typing in a text box.
local farmKey = farmBox:Row({ Title = "Toggle Farm Key" }):Right():KeybindField({
	Flag = "ToggleFarmKey",
	Value = Enum.KeyCode.F,
	KeybindList = keybinds,
	KeybindName = "Auto Farm",
	KeybindMode = "Toggle",
})

farmBox:Row({ Title = "Speed Boost (Hold)" }):Right():KeybindField({
	Flag = "SpeedKey",
	Value = Enum.KeyCode.LeftShift,
	KeybindList = keybinds,
	KeybindName = "Speed Boost",
	KeybindMode = "Hold",
})

local targetBox = farmingTab:Groupbox({
	Side = "Right",
	Title = "Target",
	Description = "Who to farm",
	Icon = "crosshair",
})

-- PopUpButton (dropdown): Value is the index of the selected option
targetBox:Row({ Title = "Enemy" }):Right():PopUpButton({ Flag = "Enemy", Options = { "Slime", "Goblin", "Orc", "Dragon" }, Value = 1 })

-- Multi-select dropdown: Maximum > 1, Value is a list of indexes
targetBox:Row({ Title = "Drops", Subtitle = "Pick up to 3" }):Right():PopUpButton({ Flag = "Drops", Options = { "Gold", "Gems", "Items", "Pets" }, Maximum = 3 })

-- RadioButtonGroup: Value is the index of the selected option
targetBox:Row({ Title = "Priority" }):Right():RadioButtonGroup({ Flag = "Priority", Options = { "Closest", "Lowest HP" }, Value = 1 })

-- TextField (Placeholder, Value)
targetBox:Row({ Title = "Webhook" }):Right():TextField({ Flag = "Webhook", Placeholder = "https://..." })

-- ButtonRow: buttons sharing the full width (State = "Primary" | "Secondary" | "Destructive")
targetBox:ButtonRow({
	Buttons = {
		{ Label = "Teleport", State = "Primary", Pushed = function() print("Teleport!") end },
		{
			Label = "Reset",
			State = "Destructive",
			Pushed = function()
				Flags:Set("AutoFarm", false)
				Flags:Set("FarmDistance", 15)
			end,
		},
	},
})

-- Chaining: a row's right side holds several controls, in creation order.
-- This row is  ESP .......... [color] [key] [toggle]  (like Obsidian's Toggle:AddColorPicker / AddKeyPicker)
local visualsBox = farmingTab:Groupbox({
	Side = "Right",
	Title = "Visuals",
	Description = "Chained controls",
	Icon = "eye",
})

local espRow = visualsBox:Row({ Title = "ESP", Subtitle = "Highlight enemies" })

-- ColorPicker: click the swatch (saturation / brightness, hue, hex, RGB, copy / paste).
--   Transparency = number adds a transparency bar; ValueChanged gets (color, transparency).
local espColor = espRow:Right():ColorPicker({
	Flag = "EspColor",
	Value = Color3.fromRGB(0, 255, 140),
	Transparency = 0,
	Title = "ESP Color",
})

local espKey = espRow:Right():KeybindField({
	Flag = "EspKey",
	Value = Enum.KeyCode.E,
	KeybindList = keybinds,
	KeybindName = "ESP",
})

espRow:Right():Toggle({ Flag = "Esp", Value = false })

-- Same idea with just a color: the text color of the ESP labels
local namesRow = visualsBox:Row({ Title = "Show Names" })
local namesColor = namesRow:Right():ColorPicker({ Flag = "EspNameColor", Value = Color3.new(1, 1, 1), Title = "Name Color" })
namesRow:Right():Toggle({ Flag = "EspNames", Value = true })

farmingTab:Groupbox({
	Side = "Left",
	Title = "Advanced",
	Description = "Click to expand",
	Icon = "sliders-horizontal",
	Collapsed = true,
}):Row({ Title = "Debug Prints" }):Right():Toggle({ Flag = "DebugPrints" })

-- Settings tab in one call: theme, accent, menu key, watermark / keybind list toggles, unload, Configs
local settingsTab = window:Settings({
	Watermark = watermark,
	KeybindList = keybinds,
	MenuKey = Enum.KeyCode.RightControl, -- shows / hides the menu; changeable in the tab
})
track(settingsTab, "Title", "Settings")

--// 4. Logic
-- Flags:OnChanged runs on clicks, drags, Flags:Set and config loads.
-- Flags:Get("Name") reads a value anywhere.

Flags:OnChanged("AutoFarm", function(enabled: boolean)
	print("Auto farm:", enabled)
	farmKey.KeybindEntry.Active = enabled -- keep the keybind list in sync with the toggle
end)

Flags:OnChanged("ToggleFarmKey", function(key: Enum.KeyCode)
	print("Farm key is now", key.Name)
end)

-- The keybind list flips its own state when F is pressed; mirror that onto the toggle
farmKey.BindPressed = function(self, _, inputComplete: boolean)
	if not inputComplete then
		Flags:Set("AutoFarm", self:IsActive())
	end
end

Flags:OnChanged("FarmDistance", function(value: number)
	distanceLabel.Text = tostring(math.floor(value + 0.5))
end)

-- Chained ESP row: the key flips the toggle, the colors only show while their toggle is on
espKey.BindPressed = function(self, _, inputComplete: boolean)
	if not inputComplete then
		Flags:Set("Esp", not Flags:Get("Esp"))
	end
end

Flags:OnChanged("Esp", function(enabled: boolean)
	espColor.Visible = enabled
	espKey.KeybindEntry.Active = enabled
	print("ESP:", enabled)
end)

Flags:OnChanged("EspNames", function(enabled: boolean)
	namesColor.Visible = enabled
end)

Flags:OnChanged("EspColor", function(color: Color3)
	print("ESP color:", color:ToHex())
end)

Flags:OnChanged("Enemy", function(index: number)
	print("Enemy:", ({ "Slime", "Goblin", "Orc", "Dragon" })[index])
end)

-- Example loop that reads flags (stopped on unload by checking the global)
getgenv().MyHubLoaded = true

task.spawn(function()
	while getgenv().MyHubLoaded do
		if Flags:Get("AutoFarm") then
			-- farm here, using Flags:Get("FarmDistance"), Flags:Get("Enemy")...
		end

		task.wait(0.5)
	end
end)

farmKey.KeybindEntry.Active = Flags:Get("AutoFarm") == true
espKey.KeybindEntry.Active = Flags:Get("Esp") == true
espColor.Visible = Flags:Get("Esp") == true
namesColor.Visible = Flags:Get("EspNames") == true

app:Notification({
	Title = "Loaded",
	Subtitle = "RightControl (or the round button on mobile) hides the UI.",
	App = "My Hub",
	AppIcon = cascade.Symbols.checkmarkCircleFill,
	Duration = 6,
})
