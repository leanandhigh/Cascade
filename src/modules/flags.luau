--[[
	Flag registry used by the config system.

	Any component created with a `Flag` property is registered here automatically:

		row:Right():Toggle({ Flag = "AutoFarm", Value = false })

	Read / write values from anywhere:

		cascade.Flags:Get("AutoFarm")
		cascade.Flags:Set("AutoFarm", true)

	React to changes (recommended: build the UI first, then hook logic up like this):

		cascade.Flags:OnChanged("AutoFarm", function(enabled) ... end)

	Custom values (not backed by a component) can be registered too:

		cascade.Flags:Register("Waypoints", {
			Get = function() return myWaypoints end,
			Set = function(value) myWaypoints = value end,
		})

	Values loaded from a config before a flag exists are kept as "pending" and
	applied the moment that flag gets registered, so autoloading never misses
	elements that are created later.
]]

--// Variables
local Flags = {
	Registry = {},
	Pending = {},
	Listeners = {},
}

local function fire(name: string, value: any)
	local listeners = Flags.Listeners[name]

	if listeners then
		for _, callback in ipairs(table.clone(listeners)) do
			task.spawn(callback, value)
		end
	end
end

--// Private Methods
local function toAccessor(target)
	if typeof(target) ~= "table" then
		return nil
	end

	local getter = rawget(target, "Get")
	local setter = rawget(target, "Set")

	if typeof(getter) == "function" and typeof(setter) == "function" then
		return { Get = getter, Set = setter }
	end

	-- Component object: everything with a `Value` property
	return {
		Component = target,
		Get = function()
			return target.Value
		end,
		Set = function(value)
			target.Value = value
		end,
	}
end

--// Public Methods
function Flags:Register(name: string, target)
	local accessor = toAccessor(target)

	if not accessor or name == nil then
		return
	end

	name = tostring(name)
	self.Registry[name] = accessor

	-- Components report their own changes (clicks, drags, config loads) to OnChanged listeners
	if accessor.Component then
		local component = accessor.Component
		local previous = component.ValueChanged

		component.ValueChanged = function(object, value, ...)
			if previous then
				previous(object, value, ...)
			end

			fire(name, value)
		end
	end

	local pending = self.Pending[name]

	if pending ~= nil then
		self.Pending[name] = nil
		pcall(accessor.Set, pending)
	end

	return accessor
end

function Flags:Unregister(name: string)
	self.Registry[tostring(name)] = nil
end

function Flags:Get(name: string): any
	local accessor = self.Registry[tostring(name)]

	if accessor then
		local ok, value = pcall(accessor.Get)

		-- note: not `ok and value or nil`, that would turn `false` into nil and drop it from configs
		if ok then
			return value
		end
	end

	return nil
end

function Flags:Set(name: string, value: any): boolean
	local accessor = self.Registry[tostring(name)]

	if not accessor then
		self.Pending[tostring(name)] = value
		return false
	end

	local ok = pcall(accessor.Set, value)

	-- Custom Get/Set flags have no component to report the change, so report it here
	if ok and not accessor.Component then
		fire(tostring(name), value)
	end

	return ok
end

-- Runs `callback(value)` whenever the flag's value changes (user input, :Set, config load).
-- Keeps your logic separate from UI code, like Obsidian's Toggles.X:OnChanged.
-- Returns a connection with :Disconnect().
function Flags:OnChanged(name: string, callback: (value: any) -> ())
	name = tostring(name)

	local listeners = self.Listeners[name] or {}
	self.Listeners[name] = listeners
	table.insert(listeners, callback)

	return {
		Disconnect = function()
			local index = table.find(listeners, callback)

			if index then
				table.remove(listeners, index)
			end
		end,
	}
end

function Flags:Snapshot(): { [string]: any }
	local snapshot = {}

	for name in pairs(self.Registry) do
		snapshot[name] = self:Get(name)
	end

	return snapshot
end

function Flags:Apply(values: { [string]: any })
	for name, value in pairs(values) do
		self:Set(name, value)
	end
end

return Flags
