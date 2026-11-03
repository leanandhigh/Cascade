--[[
	Flag registry used by the config system.

	Any component created with a `Flag` property is registered here automatically:

		row:Right():Toggle({ Flag = "AutoFarm", Value = false })

	Read / write values from anywhere:

		cascade.Flags:Get("AutoFarm")
		cascade.Flags:Set("AutoFarm", true)

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
}

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

		return ok and value or nil
	end

	return nil
end

function Flags:Set(name: string, value: any): boolean
	local accessor = self.Registry[tostring(name)]

	if not accessor then
		self.Pending[tostring(name)] = value
		return false
	end

	return (pcall(accessor.Set, value))
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
