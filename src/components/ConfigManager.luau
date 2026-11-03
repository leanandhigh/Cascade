--[[
	ConfigManager
	A "Configs" groupbox for the Settings tab. Everything is visible at once:
	the active default, the config list, a name field, and all actions as buttons.

	settingsTab:ConfigManager({ Side = "Right" })               -- uses window.Configs
	settingsTab:ConfigManager({ Manager = cascade.Config.new({ Folder = "MyHub" }) })
]]

local types = require("@types")

return function(self, properties: types.ConfigManagerProperties): types.ConfigManagerComponent
	--// Imports
	local configModule = require("@modules/config")

	--// Variables
	properties = properties or {}

	local window = self.__window
	local manager = properties.Manager or (window and window.Configs)

	if not manager then
		manager = configModule.new(typeof(properties.Config) == "table" and properties.Config or {})
	end

	local theme = self.Theme
	local names = {}
	local selected = nil
	local typedName = ""

	--// UI
	local box = self:Groupbox({
		Title = properties.Title or "Configs",
		Subtitle = properties.Subtitle or "Save, load and auto-load your settings",
		Icon = properties.Icon or "folder-cog",
		Side = properties.Side,
		Collapsible = false,
	})

	local function row(rowProperties)
		return box:Row(rowProperties)
	end

	-- Status (always visible: which config auto-loads)
	local statusRow = row({ Title = "Auto-load", Subtitle = "No default config" })
	local statusStack = statusRow.Structures.TitleStack

	-- Config list
	local listRow = row({ Title = "Config" })
	local list = listRow:Right():PopUpButton({
		Options = {},
		ValueChanged = function(_, index)
			selected = names[index]
		end,
	})

	-- Name field
	local nameRow = row({ Title = "Name", Subtitle = "Used by Create" })
	nameRow:Right():TextField({
		Placeholder = "Config name",
		ValueChanged = function(_, value: string)
			typedName = value
		end,
		TextChanged = function(_, value: string)
			typedName = value
		end,
	})

	local function setStatus(text: string, color)
		statusStack.Subtitle = text
		statusStack.Structures.Subtitle.TextColor3 = (color or theme.Text.Secondary)[1].Value
	end

	local reportToken = 0
	local reporting = false

	local function describeDefault()
		-- Don't replace a "Saved X" / "Loaded X" message while it's still being shown
		if reporting then
			return
		end

		local name, scope = manager:GetDefault()

		if name then
			setStatus(
				string.format("%s (%s)", name, scope == "All" and "all accounts" or "this account"),
				theme.Controls.Status.Added
			)
		else
			setStatus("No default config")
		end
	end

	local function refresh(keep: string?)
		names = manager:List()
		list.Options = names

		local target = keep or selected or manager.Current
		local index = target and table.find(names, target)

		selected = index and names[index] or nil
		list.Value = index

		describeDefault()
	end

	local function report(ok: boolean, message: string?, success: string)
		setStatus(ok and success or (message or "Something went wrong"),
			ok and theme.Controls.Status.Added or theme.Controls.Status.Removed)

		reportToken += 1
		reporting = true

		local token = reportToken

		task.delay(2.5, function()
			if token == reportToken then
				reporting = false
				describeDefault()
			end
		end)
	end

	local function needSelected(): string?
		if not selected then
			report(false, "Pick a config first", "")
		end

		return selected
	end

	-- Actions: full-width button rows (no empty label on the left)
	box:ButtonRow({
		Buttons = {
			{
				Label = "Create",
				State = "Primary",
				Pushed = function()
					local name = manager:Sanitize(typedName) or manager:NextName("Unnamed")

					if manager:Exists(name) then
						report(false, name .. " already exists", "")
						return
					end

					local ok, message = manager:Save(name)
					refresh(name)
					report(ok, message, "Created " .. name)
				end,
			},
			{
				Label = "Save",
				State = "Secondary",
				Pushed = function()
					local name = needSelected()

					if name then
						local ok, message = manager:Save(name)
						report(ok, message, "Saved " .. name)
					end
				end,
			},
			{
				Label = "Load",
				State = "Secondary",
				Pushed = function()
					local name = needSelected()

					if name then
						local ok, message = manager:Load(name)
						report(ok, message, "Loaded " .. name)
					end
				end,
			},
		},
	})

	box:ButtonRow({
		Buttons = {
			{
				Label = "Refresh",
				State = "Secondary",
				Pushed = function()
					refresh()
				end,
			},
			{
				Label = "Delete",
				State = "Destructive",
				Pushed = function()
					local name = needSelected()

					if name then
						local ok = manager:Delete(name)
						selected = nil
						refresh()
						report(ok, "Could not delete " .. name, "Deleted " .. name)
					end
				end,
			},
		},
	})

	-- Defaults: per account or every account
	row({ Title = "Auto-load for this account" }):Right():Button({
		Label = "Set",
		State = "Secondary",
		Pushed = function()
			local name = needSelected()

			if name then
				manager:SetDefault(name, "Account")
				report(true, nil, name .. " loads on this account")
			end
		end,
	})
	row({ Title = "Auto-load for all accounts" }):Right():Button({
		Label = "Set",
		State = "Secondary",
		Pushed = function()
			local name = needSelected()

			if name then
				manager:SetDefault(name, "All")
				report(true, nil, name .. " loads on every account")
			end
		end,
	})
	row({ Title = "Remove auto-load" }):Right():Button({
		Label = "Clear",
		State = "Destructive",
		Pushed = function()
			manager:ClearDefault("Account")
			manager:ClearDefault("All")
			report(true, nil, "Auto-load removed")
		end,
	})

	refresh()

	-- Keep the list in sync with saves/loads made from code
	local previousChanged = manager.Options.Changed

	manager.Options.Changed = function(...)
		task.defer(refresh)

		if previousChanged then
			previousChanged(...)
		end
	end

	box.Manager = manager
	box.Refresh = function()
		refresh()
	end

	return box
end
