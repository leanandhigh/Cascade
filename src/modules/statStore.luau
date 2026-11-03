--[[
	Stat store shared by FarmStats (cards in a tab) and FarmHud (floating overlay), so both show
	the same numbers. Each stat:

		{
			Name = "Gems",          -- key used by :Set / :Increment / :Get
			Label = "Gems earned",  -- shown text (defaults to Name)
			Icon = "gem",           -- Lucide name / asset id (optional)
			Value = 0,              -- number, string, or function() -> value (re-read every second)
			Type = "Timer",         -- optional: counts up from creation / :Reset()  ("Session 01:23:45")
			Format = "short",       -- numbers: "comma" (1,234,567, default) | "short" (1.2M) | "raw"
			Prefix = "", Suffix = "",
			PerHour = true,         -- numbers: also show the rate ("1,240 · 3.1K/h")
		}
]]

local Store = {}
Store.__index = Store

--// Formatting
local function comma(number: number): string
	local negative = number < 0
	local whole = math.floor(math.abs(number))
	local fraction = math.abs(number) - whole
	local text = tostring(whole)
	local result = text

	while true do
		local replaced, count = string.gsub(result, "^(%d+)(%d%d%d)", "%1,%2")
		result = replaced

		if count == 0 then
			break
		end
	end

	if fraction > 0.005 then
		result ..= string.sub(string.format("%.2f", fraction), 2)
	end

	return (negative and "-" or "") .. result
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function short(number: number): string
	local negative = number < 0
	local value = math.abs(number)
	local index = 1

	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end

	local text

	if index == 1 then
		text = value % 1 == 0 and tostring(value) or string.format("%.1f", value)
	else
		text = string.format(value >= 100 and "%.0f" or "%.1f", value)
		text = string.gsub(text, "%.0$", "")
	end

	return (negative and "-" or "") .. text .. SUFFIXES[index]
end

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))

	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	local secs = seconds % 60

	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

Store.FormatNumber = function(number: number, format: string?): string
	if format == "short" then
		return short(number)
	elseif format == "raw" then
		return tostring(number)
	end

	return comma(number)
end
Store.Clock = clock

--// Store
function Store.new(definitions)
	local self = setmetatable({
		Stats = {}, -- ordered definitions
		ByName = {},
		Values = {},
		Started = os.clock(),
		Listeners = {},
		Alive = true,
	}, Store)

	for _, definition in ipairs(definitions or {}) do
		self:Define(definition)
	end

	-- Timers, functions and rates change on their own: refresh once a second
	task.spawn(function()
		while self.Alive do
			task.wait(1)

			if self.Alive then
				self:_fire(nil)
			end
		end
	end)

	return self
end

function Store:Define(definition)
	if typeof(definition) == "string" then
		definition = { Name = definition }
	end

	local name = tostring(definition.Name or definition.Label or ("Stat" .. (#self.Stats + 1)))

	definition.Name = name
	definition.Label = definition.Label or name

	if self.ByName[name] then
		-- redefine in place
		for index, existing in ipairs(self.Stats) do
			if existing.Name == name then
				self.Stats[index] = definition
			end
		end
	else
		table.insert(self.Stats, definition)
	end

	self.ByName[name] = definition
	definition.Start = definition.Value
	self.Values[name] = definition.Value
	self:_fire(name)

	return definition
end

function Store:Get(name: string)
	local definition = self.ByName[name]

	if not definition then
		return nil
	end

	if definition.Type == "Timer" then
		return os.clock() - (definition.TimerStart or self.Started)
	end

	local value = self.Values[name]

	if typeof(value) == "function" then
		local ok, result = pcall(value)

		return ok and result or nil
	end

	return value
end

function Store:Set(name: string, value)
	if not self.ByName[name] then
		self:Define({ Name = name, Value = value })
		return
	end

	self.Values[name] = value
	self:_fire(name)
end

function Store:Increment(name: string, amount: number?)
	local current = self:Get(name)

	self:Set(name, (typeof(current) == "number" and current or 0) + (amount or 1))
end

-- Back to the starting values (and timers to 0). With a name, only that stat.
function Store:Reset(name: string?)
	for _, definition in ipairs(self.Stats) do
		if name == nil or definition.Name == name then
			self.Values[definition.Name] = definition.Start
			definition.TimerStart = os.clock()
		end
	end

	if name == nil then
		self.Started = os.clock()
	end

	self:_fire(name)
end

-- Display text for a stat: value (formatted) and an optional secondary text (rate)
function Store:Format(name: string): (string, string?)
	local definition = self.ByName[name]

	if not definition then
		return "--", nil
	end

	local value = self:Get(name)

	if definition.Type == "Timer" then
		return clock(value or 0), nil
	end

	local text
	local rate = nil

	if typeof(value) == "number" then
		text = Store.FormatNumber(value, definition.Format)

		if definition.PerHour then
			local start = typeof(definition.Start) == "number" and definition.Start or 0
			local hours = (os.clock() - (definition.TimerStart or self.Started)) / 3600

			if hours > 1 / 360 then
				rate = Store.FormatNumber((value - start) / hours, "short") .. "/h"
			end
		end
	elseif value == nil then
		text = "--"
	else
		text = tostring(value)
	end

	return (definition.Prefix or "") .. text .. (definition.Suffix or ""), rate
end

-- callback(name?) — name is nil for the once-a-second tick / full reset
function Store:OnChanged(callback)
	table.insert(self.Listeners, callback)

	return function()
		local index = table.find(self.Listeners, callback)

		if index then
			table.remove(self.Listeners, index)
		end
	end
end

function Store:_fire(name: string?)
	for _, callback in ipairs(table.clone(self.Listeners)) do
		task.spawn(callback, name)
	end
end

function Store:Destroy()
	self.Alive = false
	table.clear(self.Listeners)
end

return Store
