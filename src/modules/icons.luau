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
	Cache = {},
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

function icons.LoadLucide(): boolean
	if icons.Loaded then
		return icons.Provider ~= nil
	end

	icons.Loaded = true

	local ok, provider = pcall(function()
		local source = game:HttpGet(LUCIDE_URL)
		local chunk = loadstring(source)

		return chunk and chunk()
	end)

	if ok and typeof(provider) == "table" and typeof(provider.GetAsset) == "function" then
		icons.Provider = provider
		return true
	end

	return false
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
		if icons.LoadLucide() then
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

	icons.Cache[name] = result or false

	return result
end

-- Sets Image / ImageRectOffset / ImageRectSize on an ImageLabel or ImageButton.
-- Returns true when an icon was applied.
function icons.Apply(target, name, fallback): boolean
	local icon = icons.Get(name)

	if not icon and fallback ~= nil then
		icon = icons.Get(fallback)
	end

	pcall(function()
		target.Image = icon and icon.Url or ""
		target.ImageRectOffset = icon and icon.ImageRectOffset or ZERO
		target.ImageRectSize = icon and icon.ImageRectSize or ZERO
		target.ScaleType = Enum.ScaleType.Fit
	end)

	return icon ~= nil
end

return icons
