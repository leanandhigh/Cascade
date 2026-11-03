--[[
	Cascade loader (MTwin HUB build)

	local cascade = loadstring(game:HttpGet("https://raw.githubusercontent.com/leanandhigh/Cascade/claude/friendly-ride-yf5y59/Loader.lua"))()

	Downloads the latest dist/dist.luau from this branch and returns the library. Tries
	game:HttpGet first, then the executor's request functions (some mobile executors have no
	HttpGet / httpget). Always downloads the newest build, so updates show up on the next run.
]]

local URL = "https://raw.githubusercontent.com/leanandhigh/Cascade/claude/friendly-ride-yf5y59/dist/dist.luau"

local function fetch(url)
	local attempts = {
		function()
			return game:HttpGet(url, true)
		end,
		function()
			return game:HttpGetAsync(url)
		end,
		function()
			local requestFunction = (syn and syn.request)
				or (http and http.request)
				or http_request
				or (fluxus and fluxus.request)
				or request

			local response = requestFunction({ Url = url, Method = "GET" })

			return response and (response.Body or response.body)
		end,
		function()
			return httpget(url)
		end,
	}

	local lastError = nil

	for _, attempt in ipairs(attempts) do
		local ok, result = pcall(attempt)

		if ok and type(result) == "string" and #result > 0 then
			return result
		end

		lastError = result
	end

	error("[Cascade] Could not download the library: " .. tostring(lastError), 2)
end

local source = fetch(URL)
local chunk, compileError = loadstring(source, "=Cascade")

if not chunk then
	error("[Cascade] Could not compile the library: " .. tostring(compileError), 2)
end

return chunk()
