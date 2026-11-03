--[[
	Icon resolver.

	Accepts, in order:
		- Lucide icon names ("settings", "house", "swords"...) — crisp sprite-sheet icons,
		  loaded once from lucide-roblox-direct (same source Obsidian uses)
		- Cascade symbol names ("gearshapeFill") or values (cascade.Symbols.gearshapeFill)
		- Asset ids (123456, "rbxassetid://123456", "rbxthumb://...", "content://...")

	Lucide needs `game:HttpGet` + `loadstring` (executors). When they are missing (eg. Studio)
	the fallback symbol passed to Apply is used instead.

	icons.Apply(imageLabel, "settings", symbols.gearshapeFill)
]]

--// Imports
local symbols = require("@modules/symbols")

--// Constants
local LUCIDE_URL = "https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/refs/heads/main/source.lua"

--// Types
export type Icon = {
	Url: string,
	ImageRectOffset: Vector2,
	ImageRectSize: Vector2,
}

--// Variables
local icons = {
	Provider = nil,
	Loaded = false,
	Loading = false,
	Cache = {},
	Pending = {}, -- targets waiting for Lucide: { target, name, fallback, spriteSize }
	Waiters = {},
}

local ZERO = Vector2.new(0, 0)

--// Private Methods
local function plain(url: string): Icon
	return { Url = url, ImageRectOffset = ZERO, ImageRectSize = ZERO }
end

local function isAsset(value: string): boolean
	return string.match(value, "^rbxassetid://") ~= nil
		or string.match(value, "^rbxasset://") ~= nil
		or string.match(value, "^rbxthumb://") ~= nil
		or string.match(value, "^content://") ~= nil
		or string.match(value, "^https?://") ~= nil
end

--// Public Methods
function icons.SetProvider(provider)
	icons.Provider = provider
	icons.Loaded = true
	table.clear(icons.Cache)
end

local applyNow

-- Loads Lucide once. Called in the background when Cascade starts, so building the UI never
-- waits on HttpGet; icons applied before it finishes are updated when it does.
function icons.LoadLucide(): boolean
	if icons.Loaded then
		return icons.Provider ~= nil
	end

	if icons.Loading then
		return false
	end

	icons.Loading = true

	local ok, provider = pcall(function()
		local source = game:HttpGet(LUCIDE_URL)
		local chunk = loadstring(source)

		return chunk and chunk()
	end)

	if ok and typeof(provider) == "table" and typeof(provider.GetAsset) == "function" then
		icons.Provider = provider
	end

	icons.Loading = false
	icons.Loaded = true
	table.clear(icons.Cache)

	local pending = icons.Pending
	icons.Pending = {}

	for _, entry in ipairs(pending) do
		pcall(applyNow, entry[1], entry[2], entry[3], entry[4])
	end

	local waiters = icons.Waiters
	icons.Waiters = {}

	for _, callback in ipairs(waiters) do
		task.spawn(callback)
	end

	return icons.Provider ~= nil
end

local symbolValues = nil

-- True for monochrome glyphs (Lucide icons, Cascade symbols) that should take a theme colour;
-- false for real images such as your logo (asset ids, thumbnails), which keep their own colours.
function icons.IsGlyph(name): boolean
	if name == nil then
		return false
	end

	local icon = icons.Get(name)

	if icon and icon.ImageRectSize.X > 0 then
		return true
	end

	if typeof(name) == "string" then
		if symbols[name] then
			return true
		end

		if not symbolValues then
			symbolValues = {}

			for _, id in pairs(symbols) do
				symbolValues[id] = true
			end
		end

		return symbolValues[name] == true
	end

	return false
end

-- Runs `callback` once Lucide finished loading (right away if it already has)
function icons.WhenReady(callback: () -> ())
	if icons.Loaded then
		task.spawn(callback)
	else
		table.insert(icons.Waiters, callback)
	end
end

function icons.Get(name): Icon?
	if name == nil or name == "" then
		return nil
	end

	if typeof(name) == "number" then
		return plain("rbxassetid://" .. tostring(name))
	end

	if typeof(name) ~= "string" then
		return nil
	end

	if icons.Cache[name] ~= nil then
		return icons.Cache[name] or nil
	end

	local result = nil

	if tonumber(name) then
		result = plain("rbxassetid://" .. name)
	elseif isAsset(name) then
		result = plain(name)
	else
		-- Lucide first (kebab-case names), then Cascade symbols (camelCase names)
		if icons.Provider then
			local ok, asset = pcall(icons.Provider.GetAsset, name)

			if ok and asset then
				result = {
					Url = asset.Url,
					ImageRectOffset = asset.ImageRectOffset or ZERO,
					ImageRectSize = asset.ImageRectSize or ZERO,
				}
			end
		end

		if not result and symbols[name] then
			result = plain(symbols[name])
		end
	end

	-- Don't cache misses while Lucide is still loading, the name may resolve once it's in
	if result or icons.Loaded then
		icons.Cache[name] = result or false
	end

	return result
end

function applyNow(target, name, fallback, spriteSize: number?): boolean
	local icon = icons.Get(name)

	if not icon and fallback ~= nil then
		icon = icons.Get(fallback)
	end

	pcall(function()
		target.Image = icon and icon.Url or ""
		target.ImageRectOffset = icon and icon.ImageRectOffset or ZERO
		target.ImageRectSize = icon and icon.ImageRectSize or ZERO
		target.ScaleType = Enum.ScaleType.Fit

		-- Lucide glyphs fill their whole box (SF symbols have built-in margin), so they get a smaller box
		if spriteSize and icon and icon.ImageRectSize.X > 0 then
			target.Size = UDim2.fromOffset(spriteSize, spriteSize)
		end
	end)

	return icon ~= nil
end

-- Sets Image / ImageRectOffset / ImageRectSize on an ImageLabel or ImageButton.
-- `spriteSize` (optional) resizes the image when a Lucide sprite is used.
-- Returns true when an icon was (or will be, once Lucide loads) applied.
function icons.Apply(target, name, fallback, spriteSize: number?): boolean
	if name == nil and fallback == nil then
		return false
	end

	local applied = applyNow(target, name, fallback, spriteSize)

	-- Lucide still loading and this looks like a Lucide name: update it when it arrives
	if icons.Loading and typeof(name) == "string" and string.find(name, "^[%l%d%-]+$") then
		table.insert(icons.Pending, { target, name, fallback, spriteSize })

		return true
	end

	return applied
end

return icons
