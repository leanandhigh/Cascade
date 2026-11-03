--[[
	Dashboard
	A ready-made home tab: update logs + community links, built from Cascade components.

	local dashboard = window:Dashboard({
		Version = "1.0.16",
		Logs = {
			"+ More maps in Dungeon and Macro settings",
			"~ Card priority could stop the script from loading",
		},
		LinksTitle = "bocchi reworked \\ Anime Adventures",
		Discord = "https://discord.gg/xxxxxx",
	})

	dashboard:Log("+ Something new")             -- add an update log entry later
	dashboard:PageSection({ Title = "More" })    -- the dashboard is a normal page, add anything to it
]]

local types = require("@types")

return function(self, properties: types.DashboardProperties): types.Dashboard
	--// Imports
	local symbols = require("@modules/symbols")

	--// Variables
	properties = properties or {}

	local tab = self:Tab({
		Title = properties.Title or "Dashboard",
		Icon = properties.Icon or symbols.houseFill,
		Selected = properties.Selected ~= false,
	})

	local object = {
		Type = "Dashboard",
		Theme = self.Theme,
		Tab = tab,
		__container = tab.__container,
		__window = self.__window or self,
	}

	--// Updates
	local updates = tab:PageSection({
		Title = properties.UpdatesTitle or "Updates",
		Subtitle = properties.Version and ("Version " .. tostring(properties.Version)) or nil,
	})

	object.UpdateLog = updates:UpdateLog({
		Title = properties.LogsTitle or "Update Logs",
		Preview = properties.Preview or 5,
		Entries = properties.Logs or {},
	})

	--// Links (Discord / websites / anything copyable)
	local links = properties.Links or {}

	if properties.Discord then
		table.insert(links, 1, {
			Title = "Discord",
			Subtitle = "Click the invite to copy.",
			Invite = properties.Discord,
		})
	end

	object.Links = {}

	if #links > 0 then
		local section = tab:PageSection({
			Title = properties.LinksTitle or "Community",
		})

		for _, link in ipairs(links) do
			table.insert(object.Links, section:InviteCard(link))
		end
	end

	--// Methods
	object.Log = function(_, entry)
		return object.UpdateLog:Add(entry)
	end

	-- Everything else (PageSection, Groupbox, Form...) is forwarded to the tab, so the
	-- dashboard behaves like a normal page.
	return setmetatable(object, { __index = tab })
end
