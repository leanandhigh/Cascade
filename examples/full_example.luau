--// 1. Load Cascade
local CASCADE_URL = "https://raw.githubusercontent.com/leanandhigh/Cascade/claude/friendly-ride-yf5y59/dist/dist.luau"

local source = game:HttpGet(CASCADE_URL)
local chunk, compileError = loadstring(source, "Cascade")
assert(chunk, "Cascade failed to compile: " .. tostring(compileError))

local cascade = chunk()
assert(type(cascade) == "table" and cascade.New, "Cascade did not load, check CASCADE_URL")

local Flags = cascade.Flags

--// Services
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")

local localPlayer = players.LocalPlayer
local connections = {}

--// Language
local texts = {
	EN = { Main = "Main", Farming = "Farming", AutoFarm = "Auto Farm", AutoFarmInfo = "Automatically farms the selected enemy.", Settings = "Settings" },
	TH = { Main = "หลัก", Farming = "ฟาร์ม", AutoFarm = "ฟาร์มอัตโนมัติ", AutoFarmInfo = "ฟาร์มศัตรูที่เลือกโดยอัตโนมัติ", Settings = "ตั้งค่า" },
}
local translatable = {}

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
local FONT = "rbxassetid://12187365364"
cascade.SetFont(FONT)

local LOGO_ID = 77668182651543
local LOGO = LOGO_ID ~= 0 and ("rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=150&h=150")
	or ("rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150")

--// 2. App, overlays and window
local app = cascade.New({
	WindowPill = true,
	Theme = cascade.Themes.Dark,
	Accent = cascade.Accents.Blue,
})

local watermark = app:Watermark({
	Title = "MTwin HUB",
	Icon = LOGO,
	Text = "Premium",
})

local keybinds = app:KeybindList({
	Title = "Keybinds",
})

local window = app:Window({
	Title = "MTwin HUB",
	Subtitle = "https://discord.gg/y35kyZM8sV",
	Size = userInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530),
	Scale = 1,
	UIBlur = false,

	Logo = LOGO,
	Brand = "MTwin HUB",
	BrandSubtitle = "Premium",

	ProfileName = localPlayer.Name,

	KeyExpires = os.time() + 3 * 86400 + 4 * 3600,
	KeyExpired = function()
		app:Notification({ Title = "Key expired", Subtitle = "Get a new key to keep using the script.", App = "MTwin HUB", Duration = 10 })
	end,

	Languages = { "EN", "TH" },
	Language = "EN",
	LanguageChanged = function(_, language: string)
		applyLanguage(language)
	end,

	Config = {
		Folder = "MTwinHub",
		SubFolder = tostring(game.PlaceId),
		AutoLoad = true,
	},

	Unloaded = function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		getgenv().MTwinHubLoaded = nil
	end,
})

--// 3. UI
local dashboard = window:Dashboard({
	Updated = "4 Nov 2026",
	Logs = {

		"+ More maps in Dungeon and Macro settings",
		"~ Card priority could stop the script from loading",
		"+ Improved UI loading on slower devices",
		"+ Save Dungeon path previews by floor",
		"~ Dungeon ignores unwanted maps in current and next-floor paths",
		{ Type = "Removed", Text = "Old macro recorder" },
	},
	LinksTitle = "MTwin HUB",
	Discord = "https://discord.gg/y35kyZM8sV",
})

dashboard:Log("+ Thanks for using MTwin HUB!")

local mainSection = window:Section({ Title = "Main", Disclosure = false })
track(mainSection, "Title", "Main")

local farmingTab = mainSection:Tab({
	Title = "Farming",
	Icon = "swords",
})
track(farmingTab, "Title", "Farming")

local farmBox = farmingTab:Groupbox({
	Side = "Left",
	Title = "Auto Farm",
	Description = "Farming options",
	Icon = "sparkles",

})

local autoFarmRow = farmBox:Row({ Title = "Auto Farm", Subtitle = "Automatically farms the selected enemy." })
track(autoFarmRow.Structures.TitleStack, "Title", "AutoFarm")
track(autoFarmRow.Structures.TitleStack, "Subtitle", "AutoFarmInfo")

autoFarmRow:Right():Toggle({ Flag = "AutoFarm", Value = false })

farmBox:Row({ Title = "Auto Collect" }):Right():Toggle({ Flag = "AutoCollect", Value = true })

local statusRow = farmBox:Row({ Title = "Status: Idle" })

farmBox:Row({
	Title = "How it works",
	Subtitle = "Joins the first enabled route, farms until the wave limit, then goes back to the lobby and repeats.",
	Wrap = true,
})

local joinDelayRow = farmBox:Row({ Title = "Join Delay (seconds)" })
joinDelayRow:Right():Slider({ Flag = "JoinDelay", Minimum = 0, Maximum = 30, Value = 5 })
local joinDelayLabel = joinDelayRow:Right():Label({ Text = "5" })

local distanceRow = farmBox:Row({ Title = "Farm Distance", DependsOn = "AutoFarm" })
distanceRow:Right():Slider({ Flag = "FarmDistance", Minimum = 5, Maximum = 50, Value = 15 })
local distanceLabel = distanceRow:Right():Label({ Text = "15" })

farmBox:Row({ Title = "Wave Count", ShowIf = "AutoFarm" }):Right():Stepper({ Flag = "WaveCount", Minimum = 1, Maximum = 50, Step = 1, Value = 10, Fielded = true })

farmBox:Row({ Title = "Toggle Farm Key" }):Right():KeybindField({
	Flag = "ToggleFarmKey",
	Value = Enum.KeyCode.F,
	KeybindList = keybinds,
	KeybindName = "Auto Farm",
	KeybindMode = "Toggle",
	ToggleFlag = "AutoFarm",
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

targetBox:Row({ Title = "Enemy" }):Right():PopUpButton({ Flag = "Enemy", Options = { "Slime", "Goblin", "Orc", "Dragon" }, Value = 1 })

targetBox:Row({ Title = "Drops", Subtitle = "Pick up to 3" }):Right():PopUpButton({ Flag = "Drops", Options = { "Gold", "Gems", "Items", "Pets" }, Maximum = 3 })

targetBox:Row({ Title = "Priority" }):Right():RadioButtonGroup({ Flag = "Priority", Options = { "Closest", "Lowest HP" }, Value = 1 })

targetBox:Row({ Title = "Webhook" }):Right():TextField({ Flag = "Webhook", Placeholder = "https://..." })

targetBox:ButtonRow({
	Buttons = {
		{ Label = "Teleport", State = "Primary", Pushed = function() print("Teleport!") end },
		{ Label = "Server Hop", State = "Secondary", Disabled = true },
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

local visualsBox = farmingTab:Groupbox({
	Side = "Right",
	Title = "Visuals",
	Description = "Chained controls",
	Icon = "eye",
})

local espRow = visualsBox:Row({ Title = "ESP", Subtitle = "Highlight enemies" })

local espColor = espRow:Right():ColorPicker({
	Flag = "EspColor",
	Value = Color3.fromRGB(0, 255, 140),
	Transparency = 0,
	Title = "ESP Color",
})

espRow:Right():KeybindField({
	Flag = "EspKey",
	Value = Enum.KeyCode.E,
	KeybindList = keybinds,
	KeybindName = "ESP",
	ToggleFlag = "Esp",
})

espRow:Right():Toggle({ Flag = "Esp", Value = false })

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

local teleportTab = mainSection:Tab({ Title = "Teleport", Icon = "map-pin" })

teleportTab:PageSection({ Title = "Priority teleport" }):PriorityList({
	Flag = "JoinPriority",
	Title = "Join priority",
	Subtitle = "Top enabled route wins; routing repeats after every visit to the lobby.",
	Columns = 2,
	Values = {
		"Auto Join Challenge",
		"Auto Join Story / Inf",
		"Auto Infinity Castle",
		"Auto Join Dungeon",
		"Auto Open Portal",
		"Auto Find Match",
		"Auto Daily Challenge",
		"Auto Summer Hunt",
	},
})

getgenv().MTwinSessionStart = getgenv().MTwinSessionStart or os.time()

local farmStats = app:FarmStats({
	Title = "MTwin HUB",
	Subtitle = "https://discord.gg/y35kyZM8sV",
	Icon = LOGO,
	Status = "Online",
	SessionText = "SESSION TIME",
	StartedText = "Started  ",
	Stats = {
		{ Name = "Level", Value = 225 },
		{ Name = "Money", Value = 8433620 },
		{ Name = "Wins", Value = 0, Icon = "trophy" },
		{ Name = "Gems", Value = 33125, Format = "short", PerHour = true },
	},
	Materials = {
		{ Name = "Star Fruit", Count = 70, Gain = 2 },
		{ Name = "Trait Crystal", Count = 12, Gain = 0 },
		{ Name = "Gold Ore", Count = 1840, Gain = 120 },
		{ Name = "Raid Keys", Count = "3 / 10", Gain = 1 },
	},
	VisibleChanged = function(_, visible)
		Flags:Set("FarmScreen", visible)
	end,
})

farmStats:SetSession(getgenv().MTwinSessionStart)

local hud = app:FarmHud({
	Title = "MTwin HUB",
	Width = 300,
	Icon = LOGO,
	Source = farmStats,
	Only = { "Wins", "Gems" },
	StatusFlag = "AutoFarm",
	Button = { Text = "Black", Callback = function() farmStats:Toggle() end },
})

local screenBox = farmingTab:Groupbox({ Side = "Left", Title = "Farm screen", Icon = "monitor" })
screenBox:Row({ Title = "Black screen" }):Right():Toggle({ Flag = "FarmScreen", Value = false })
screenBox:Row({ Title = "Farm HUD" }):Right():Toggle({ Flag = "ShowFarmHud", Value = true })
screenBox:ButtonRow({
	Buttons = {
		{ Label = "Reset session", State = "Secondary", Pushed = function() farmStats:Reset() hud:ResetTimer() end },
	},
})

local settingsTab = window:Settings({
	Watermark = watermark,
	KeybindList = keybinds,
	MenuKey = Enum.KeyCode.RightControl,
})
track(settingsTab, "Title", "Settings")

settingsTab.Interface:Row({ Title = "Rejoin on kick" }):Right():Toggle({ Flag = "AutoRejoin", Value = false })

--// 4. Logic
Flags:OnChanged("JoinPriority", function(order)
	print("Join priority:", table.concat(order, " > "))
end)

Flags:OnChanged("FarmScreen", function(enabled: boolean)
	farmStats:SetVisible(enabled)
end)

Flags:OnChanged("ShowFarmHud", function(enabled: boolean)
	hud.Visible = enabled
end)

Flags:OnChanged("AutoFarm", function(enabled: boolean)
	print("Auto farm:", enabled)
end)

Flags:OnChanged("ToggleFarmKey", function(key: Enum.KeyCode)
	print("Farm key is now", key.Name)
end)

Flags:OnChanged("FarmDistance", function(value: number)
	distanceLabel.Text = tostring(math.floor(value + 0.5))
end)

Flags:OnChanged("JoinDelay", function(value: number)
	joinDelayLabel.Text = tostring(math.floor(value + 0.5))
end)

Flags:OnChanged("Esp", function(enabled: boolean)
	espColor.Visible = enabled
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

getgenv().MTwinHubLoaded = true

task.spawn(function()
	while getgenv().MTwinHubLoaded do
		if Flags:Get("AutoFarm") then
			statusRow.Title = string.format("Status: Match: wave %d, %d units placed", math.random(1, 15), math.random(1, 40))
			farmStats:Increment("Gems", math.random(5, 20))
			farmStats:UpdateMaterial("Gold Ore", (farmStats:Get("Gems") or 0) // 10, 4)
			hud:SetItems({ { Name = "Gold Ore", Amount = 4 }, { Name = "Star Fruit", Amount = 1 } })
		else
			statusRow.Title = "Status: Idle"
		end

		task.wait(0.5)
	end
end)

espColor.Visible = Flags:Get("Esp") == true
namesColor.Visible = Flags:Get("EspNames") == true

app:Notification({
	Title = "Loaded",
	Subtitle = "RightControl (or the round button on mobile) hides the UI.",
	App = "MTwin HUB",
	AppIcon = cascade.Symbols.checkmarkCircleFill,
	Duration = 6,
})
