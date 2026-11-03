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

	--// Variables
	properties = properties or {}

	local tab = self:Tab({
		Title = properties.Title or "Dashboard",
		Icon = properties.Icon or "house",
		Selected = properties.Selected ~= false,
	})

	local object = {
		Type = "Dashboard",
		Theme = self.Theme,
		HomeTab = tab,
		__container = tab.__container,
		__window = self.__window or self,
	}

	--// Information (shown first, nothing hidden: player, key time, game, executor, version)
	local window = self.__window or self

	if properties.Info ~= false then
		local gameName = "Loading..."

		task.spawn(function()
			local ok, info = pcall(function()
				return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
			end)

			gameName = ok and info and info.Name or tostring(game.PlaceId)
		end)

		local executor = "Unknown"

		pcall(function()
			if identifyexecutor then
				local name, version = identifyexecutor()
				executor = version and (tostring(name) .. " " .. tostring(version)) or tostring(name)
			elseif getexecutorname then
				executor = tostring(getexecutorname())
			end
		end)

		local items = {}

		if window.DisplayName then
			table.insert(items, {
				Label = "Player",
				Value = function()
					return window:DisplayName()
				end,
			})
		end

		if window.KeyStatus then
			table.insert(items, {
				Label = "Key",
				Value = function()
					local text, color = window:KeyStatus()

					-- "Key: 3d 04:00:00" -> "3d 04:00:00" (the row label already says Key)
					return (string.gsub(text, "^Key: ", "")), color
				end,
			})
		end

		table.insert(items, {
			Label = "Game",
			Value = function()
				return gameName
			end,
		})
		table.insert(items, { Label = "Executor", Value = executor })

		if properties.Version then
			table.insert(items, { Label = "Version", Value = tostring(properties.Version) })
		end

		for _, item in ipairs(typeof(properties.Info) == "table" and properties.Info or {}) do
			table.insert(items, item)
		end

		object.Info = tab:InfoCard({
			Title = properties.InfoTitle or "Information",
			Icon = "info",
			Items = items,
		})
	end

	--// Updates
	local updates = tab:PageSection({
		Title = properties.UpdatesTitle or "Updates",
	})

	object.Updates = updates:UpdateLog({
		Title = properties.LogsTitle or "What's new",
		Subtitle = properties.LogsSubtitle
			or (properties.Version and ("Version " .. tostring(properties.Version)) or nil),
		-- Every entry is visible by default; pass Preview = 5 to collapse behind "View all"
		Preview = properties.Preview or math.huge,
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
			table.insert(object.Links, (section:InviteCard(link)))
		end
	end

	--// Methods
	object.Log = function(_, entry)
		return object.Updates:Add(entry)
	end

	-- Everything else (PageSection, Groupbox, Form...) is forwarded to the tab, so the
	-- dashboard behaves like a normal page.
	-- Note: field names must not match component names (Tab, UpdateLog...), the component
	-- wrapper assigns every component constructor onto returned objects.
	return setmetatable(object, { __index = tab })
end
