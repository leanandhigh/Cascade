--// Imports
local binder = require("@modules/binder")
local appRecorder = require("@modules/appRecorder")
local flags = require("@modules/flags")
local disabledLook = require("@modules/disabled")

--// Variables
local components = {
	Window = require("@components/Window"),
	Section = require("@components/Section"),
	Tab = require("@components/Tab"),
	PageSection = require("@components/PageSection"),
	Form = require("@components/Form"),
	Row = require("@components/Row"),
	HStack = require("@components/HStack"),
	VStack = require("@components/VStack"),
	TitleStack = require("@components/TitleStack"),
	Label = require("@components/Label"),
	Symbol = require("@components/Symbol"),
	Toggle = require("@components/Toggle"),
	TextField = require("@components/TextField"),
	KeybindField = require("@components/KeybindField"),
	Slider = require("@components/Slider"),
	Button = require("@components/Button"),
	Stepper = require("@components/Stepper"),
	RadioButtonGroup = require("@components/RadioButtonGroup"),
	PopUpButton = require("@components/PopUpButton"),
	PullDownButton = require("@components/PullDownButton"),
	Page = require("@components/Page"),
	Notification = require("@components/Notification"),
	ImageSurface = require("@components/ImageSurface"),
	Groupbox = require("@components/Groupbox"),
	Columns = require("@components/Columns"),
	UpdateLog = require("@components/UpdateLog"),
	InviteCard = require("@components/InviteCard"),
	Dashboard = require("@components/Dashboard"),
	Watermark = require("@components/Watermark"),
	KeybindList = require("@components/KeybindList"),
	InfoCard = require("@components/InfoCard"),
	ConfigManager = require("@components/ConfigManager"),
	Settings = require("@components/Settings"),
	ButtonRow = require("@components/ButtonRow"),
	ColorPicker = require("@components/ColorPicker"),
	PriorityList = require("@components/PriorityList"),
	FarmStats = require("@components/FarmStats"),
	FarmHud = require("@components/FarmHud"),
}

--// Initialize
local function traceback(message)
	if debug and debug.traceback then
		return debug.traceback(message)
	end

	return tostring(message)
end

local function wrap(name, make)
	return function(self, ...)
		local args = table.pack(...)
		local recorder = appRecorder.FromContext(self)
		local recordNode = recorder and recorder:_Begin(self, name, args[1])
		local ok, result, raw = xpcall(function()
			return make(self, table.unpack(args, 1, args.n))
		end, traceback)

		if not ok then
			if recorder then
				recorder:_Cancel(recordNode)
			end

			error(result, 2)
		end

		if
			typeof(result) == "Instance"
			or (typeof(result) == "table" and getmetatable(result) and typeof(getmetatable(result)) == "Instance")
		then
			raw = result
			result = binder.Wrap({}, {}, result)
		end

		if typeof(result) == "table" then
			if result.Type == nil then
				result.Type = name
			end

			if result.Theme == nil and self and self.Theme then
				result.Theme = self.Theme
			end
		end

		binder.Apply(components, result)

		-- Anything created with a `Flag` is saved / loaded by the config system
		local componentProperties = args[1]

		if typeof(componentProperties) == "table" and componentProperties.Flag ~= nil and typeof(result) == "table" then
			flags:Register(componentProperties.Flag, result)
		end

		-- Disabled / DependsOn / ShowIf for every element (see modules/disabled)
		if typeof(result) == "table" and name ~= "Window" then
			local body = nil

			pcall(function()
				local structures = rawget(result, "Structures") or result.Structures
				local candidate = structures and structures.Body

				if typeof(candidate) == "table" then
					candidate = candidate.__instance
				end

				body = typeof(candidate) == "Instance" and candidate or nil
			end)

			if body and body:IsA("GuiObject") then
				local theme = self and self.Theme
				local manual = false
				local dependency = false

				local function refresh()
					disabledLook.Apply(body, theme, manual or dependency)
				end

				pcall(function()
					result.SetDisabled = function(_, value: boolean)
						manual = value == true
						refresh()
					end
					result.IsDisabled = function()
						return manual or dependency
					end
				end)

				if typeof(componentProperties) == "table" then
					manual = componentProperties.Disabled == true

					local dependsOn = componentProperties.DependsOn
					local dependsFlag = disabledLook.FlagOf(dependsOn)

					if dependsFlag then
						local function update(value)
							dependency = not disabledLook.Condition(dependsOn, value)
							refresh()
						end

						update(flags:Get(dependsFlag))
						flags:OnChanged(dependsFlag, update)
					end

					local showIf = componentProperties.ShowIf
					local showFlag = disabledLook.FlagOf(showIf)

					if showFlag then
						local function update(value)
							body.Visible = disabledLook.Condition(showIf, value)
						end

						update(flags:Get(showFlag))
						flags:OnChanged(showFlag, update)
					end

					if manual then
						refresh()
					end
				end
			end
		end

		local final = raw
			or (
				typeof(result) == "table"
				and pcall(function()
					return result.__instance
				end)
				and result.__instance
			)

		if final ~= nil then
			table.insert(__SH.COMPINDEXES, final)

			if recorder then
				recorder:_Commit(recordNode, result, final)
			end

			return result, final
		end

		if recorder then
			recorder:_Commit(recordNode, result, nil)
		end

		return result
	end
end

for name, make in pairs(components) do
	components[name] = wrap(name, make)
end

function components.register(name: string, make: (any, any) -> any)
	components[name] = wrap(name, make)
end

return components
