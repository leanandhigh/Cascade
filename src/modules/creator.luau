local types = require("@types")
local binder = require("./binder")

local creator = {}

-- Instances whose colours depend on their own state (__contextKeys: toggle on/off, tab selected...).
-- Their dynamic keys only listen to ONE theme value, so a theme / accent change that only touches
-- another value (eg. Toggle.SwitchOn) left them on the old colour. RefreshContext re-applies them.
local contextual = {}

function creator.RefreshContext()
	for instance, contextKeys in pairs(contextual) do
		if contextKeys._general then
			pcall(contextKeys._general)
		end

		for property, compute in pairs(contextKeys) do
			if property ~= "_general" then
				pcall(function()
					local value = compute()

					if value ~= nil then
						instance[property] = value
					end
				end)
			end
		end
	end
end

function creator.Value(value: any): types.ValueState
	local callbacks = {}
	local state = {
		Value = value,
		Connect = function(self, fn)
			table.insert(callbacks, fn)
			return fn
		end,
	}

	return binder.Wrap(state, {
		Value = function(newValue)
			-- Re-applying a theme sets every value again; only notify listeners on a real change,
			-- otherwise every themed instance re-renders (thousands of deferred updates on load).
			if newValue == state.Value then
				return
			end

			for _, callback in pairs(callbacks) do
				pcall(callback, newValue)
			end
		end,
	})
end

function creator.Create(className: string)
	return function(properties)
		properties = properties or {}

		local instance = Instance.new(className)

		if typeof(properties.__contextKeys) == "table" then
			contextual[instance] = properties.__contextKeys

			instance.Destroying:Connect(function()
				contextual[instance] = nil
			end)
		end

		for key, value in pairs(properties) do
			if key == "__dynamicKeys" and type(value) == "table" then
				for property, valueObject: types.ValueState in pairs(value) do
					pcall(function()
						instance[property] = valueObject.Value
					end)

					valueObject:Connect(function(newValue)
						task.defer(pcall, function()
							if properties["__contextKeys"] and properties["__contextKeys"]["_general"] then
								properties["__contextKeys"]["_general"]()
							end

							instance[property] = properties["__contextKeys"]
									and properties["__contextKeys"][property]
									and properties["__contextKeys"][property]()
								or newValue
						end)
					end)
				end

				continue
			end

			if typeof(value) == "table" and value.__unique then
				value.Parent = instance
			end

			pcall(function()
				instance[key] = value
			end)
		end

		return setmetatable({ __unique = true }, {
			__metatable = instance,
			__index = function(_, key)
				if key == "__instance" then
					return instance
				end

				local value = instance[key]

				if typeof(value) == "function" then
					return function(_, ...)
						return value(instance, ...)
					end
				else
					return value
				end
			end,
			__newindex = function(_, key, value)
				instance[key] = value
			end,
		})
	end
end

return creator
