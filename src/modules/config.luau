--[[
	Config manager — saves / loads every registered flag to JSON files.

	Layout on disk:
		<Folder>/<SubFolder?>/configs/<name>.json
		<Folder>/<SubFolder?>/defaults.json   -- { All = "name", Accounts = { [userId] = "name" } }

	A default (autoload) config can be set for *this account only* or for *all
	accounts*. When loading the default, the account default wins over the
	all-accounts default.

	Falls back to an in-memory store when the environment has no file
	functions (eg. Studio), so the UI keeps working.
]]

--// Imports
local services = require("@modules/services")
local flags = require("@modules/flags")

--// References
local httpService = services.HttpService
local players = services.Players

--// Types
export type ConfigOptions = {
	Folder: string?,
	SubFolder: string?,
	AutoLoad: boolean?,
	Ignore: { string }?,

	Saved: ((name: string) -> ())?,
	Loaded: ((name: string) -> ())?,
	Deleted: ((name: string) -> ())?,
	Changed: (() -> ())?,
}

--// Constants
local INVALID_CHARACTERS = '[\\/:%*%?"<>|]'

--// Variables
local Config = {}
Config.__index = Config

--// Filesystem (executor functions with an in-memory fallback)
local memory = {}

local fs = {}

local function has(fn)
	return typeof(fn) == "function"
end

function fs.isfolder(path: string): boolean
	if has(isfolder) then
		local ok, result = pcall(isfolder, path)
		return ok and result == true
	end

	return memory[path] == true
end

function fs.makefolder(path: string)
	if has(makefolder) then
		pcall(makefolder, path)
	else
		memory[path] = true
	end
end

function fs.isfile(path: string): boolean
	if has(isfile) then
		local ok, result = pcall(isfile, path)
		return ok and result == true
	end

	return typeof(memory[path]) == "string"
end

function fs.readfile(path: string): string?
	if has(readfile) then
		local ok, result = pcall(readfile, path)
		return ok and result or nil
	end

	local value = memory[path]
	return typeof(value) == "string" and value or nil
end

function fs.writefile(path: string, content: string)
	if has(writefile) then
		pcall(writefile, path, content)
	else
		memory[path] = content
	end
end

function fs.delfile(path: string)
	if has(delfile) then
		pcall(delfile, path)
	else
		memory[path] = nil
	end
end

function fs.listfiles(path: string): { string }
	if has(listfiles) then
		local ok, result = pcall(listfiles, path)
		return ok and result or {}
	end

	local files = {}
	local prefix = path .. "/"

	for key, value in pairs(memory) do
		if typeof(value) == "string" and string.sub(key, 1, #prefix) == prefix then
			table.insert(files, key)
		end
	end

	return files
end

--// Serialization (Roblox datatypes -> JSON friendly)
local function encodeValue(value)
	local kind = typeof(value)

	if kind == "EnumItem" then
		return { __type = "EnumItem", enum = tostring(value.EnumType), name = value.Name }
	elseif kind == "Color3" then
		return { __type = "Color3", hex = value:ToHex() }
	elseif kind == "UDim2" then
		return { __type = "UDim2", value = { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset } }
	elseif kind == "Vector2" then
		return { __type = "Vector2", value = { value.X, value.Y } }
	elseif kind == "Vector3" then
		return { __type = "Vector3", value = { value.X, value.Y, value.Z } }
	elseif kind == "table" then
		local copy = {}

		for key, item in pairs(value) do
			copy[key] = encodeValue(item)
		end

		return copy
	elseif kind == "number" or kind == "string" or kind == "boolean" then
		return value
	end

	return nil
end

local function decodeValue(value)
	if typeof(value) ~= "table" then
		return value
	end

	local kind = value.__type

	if kind == "EnumItem" then
		local ok, item = pcall(function()
			return (Enum :: any)[value.enum][value.name]
		end)

		return ok and item or nil
	elseif kind == "Color3" then
		return Color3.fromHex(value.hex)
	elseif kind == "UDim2" then
		return UDim2.new(table.unpack(value.value))
	elseif kind == "Vector2" then
		return Vector2.new(table.unpack(value.value))
	elseif kind == "Vector3" then
		return Vector3.new(table.unpack(value.value))
	end

	local copy = {}

	for key, item in pairs(value) do
		copy[key] = decodeValue(item)
	end

	return copy
end

--// Public Methods
function Config.new(options: ConfigOptions?)
	options = options or {}

	local folder = options.Folder or "Cascade"

	if options.SubFolder then
		folder ..= "/" .. tostring(options.SubFolder)
	end

	local self = setmetatable({
		Options = options,
		Folder = folder,
		ConfigFolder = folder .. "/configs",
		DefaultsFile = folder .. "/defaults.json",
		Current = nil,
		Ignore = {},
	}, Config)

	for _, name in ipairs(options.Ignore or {}) do
		self.Ignore[name] = true
	end

	self:EnsureFolders()

	return self
end

function Config:EnsureFolders()
	local built = ""

	for part in string.gmatch(self.ConfigFolder, "[^/]+") do
		built = built == "" and part or (built .. "/" .. part)

		if not fs.isfolder(built) then
			fs.makefolder(built)
		end
	end
end

function Config:Notify(callbackName: string, ...)
	local callback = self.Options[callbackName]

	if callback then
		task.spawn(callback, ...)
	end

	if callbackName ~= "Changed" and self.Options.Changed then
		task.spawn(self.Options.Changed)
	end
end

function Config:Path(name: string): string
	return self.ConfigFolder .. "/" .. name .. ".json"
end

function Config:Sanitize(name: string?): string?
	if typeof(name) ~= "string" then
		return nil
	end

	name = string.gsub(name, INVALID_CHARACTERS, "")
	name = string.match(name, "^%s*(.-)%s*$")

	return name ~= "" and name or nil
end

function Config:Exists(name: string): boolean
	return fs.isfile(self:Path(name))
end

function Config:List(): { string }
	self:EnsureFolders()

	local names = {}

	for _, path in ipairs(fs.listfiles(self.ConfigFolder)) do
		local name = string.match(path, "([^/\\]+)%.json$")

		if name then
			table.insert(names, name)
		end
	end

	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return names
end

function Config:NextName(base: string?): string
	base = base or "Unnamed"

	local index = 0

	while self:Exists(base .. index) do
		index += 1
	end

	return base .. index
end

function Config:Save(name: string?): (boolean, string?)
	name = self:Sanitize(name or self.Current)

	if not name then
		return false, "Invalid config name"
	end

	local values = {}

	for flag, value in pairs(flags:Snapshot()) do
		if not self.Ignore[flag] then
			values[flag] = encodeValue(value)
		end
	end

	local ok, encoded = pcall(httpService.JSONEncode, httpService, {
		Version = 1,
		Flags = values,
	})

	if not ok then
		return false, "Failed to encode config"
	end

	self:EnsureFolders()
	fs.writefile(self:Path(name), encoded)

	self.Current = name
	self:Notify("Saved", name)

	return true
end

function Config:Load(name: string?): (boolean, string?)
	name = self:Sanitize(name or self.Current)

	if not name or not self:Exists(name) then
		return false, "Config does not exist"
	end

	local content = fs.readfile(self:Path(name))
	local ok, decoded = pcall(httpService.JSONDecode, httpService, content or "")

	if not ok or typeof(decoded) ~= "table" then
		return false, "Failed to decode config"
	end

	local values = decoded.Flags or decoded

	for flag, value in pairs(values) do
		if not self.Ignore[flag] then
			flags:Set(flag, decodeValue(value))
		end
	end

	self.Current = name
	self:Notify("Loaded", name)

	return true
end

function Config:Delete(name: string?): boolean
	name = self:Sanitize(name or self.Current)

	if not name or not self:Exists(name) then
		return false
	end

	fs.delfile(self:Path(name))

	-- Clear defaults pointing to the deleted config
	local defaults = self:ReadDefaults()

	if defaults.All == name then
		defaults.All = nil
	end

	for userId, configName in pairs(defaults.Accounts) do
		if configName == name then
			defaults.Accounts[userId] = nil
		end
	end

	self:WriteDefaults(defaults)

	if self.Current == name then
		self.Current = nil
	end

	self:Notify("Deleted", name)

	return true
end

function Config:Rename(from: string, to: string): (boolean, string?)
	to = self:Sanitize(to)

	if not to then
		return false, "Invalid config name"
	end

	if from == to then
		return true
	end

	if self:Exists(to) then
		return false, "A config with that name already exists"
	end

	local content = fs.readfile(self:Path(from))

	if not content then
		return false, "Config does not exist"
	end

	fs.writefile(self:Path(to), content)
	fs.delfile(self:Path(from))

	local defaults = self:ReadDefaults()

	if defaults.All == from then
		defaults.All = to
	end

	for userId, configName in pairs(defaults.Accounts) do
		if configName == from then
			defaults.Accounts[userId] = to
		end
	end

	self:WriteDefaults(defaults)

	if self.Current == from then
		self.Current = to
	end

	self:Notify("Changed")

	return true
end

--// Defaults (autoload)
local function accountKey(): string
	local player = players.LocalPlayer

	return player and tostring(player.UserId) or "0"
end

function Config:ReadDefaults()
	local content = fs.readfile(self.DefaultsFile)
	local ok, decoded = pcall(httpService.JSONDecode, httpService, content or "")

	if not ok or typeof(decoded) ~= "table" then
		decoded = {}
	end

	decoded.Accounts = typeof(decoded.Accounts) == "table" and decoded.Accounts or {}

	return decoded
end

function Config:WriteDefaults(defaults)
	local ok, encoded = pcall(httpService.JSONEncode, httpService, defaults)

	if ok then
		fs.writefile(self.DefaultsFile, encoded)
	end
end

-- scope: "Account" (this account only) | "All" (every account)
function Config:SetDefault(name: string?, scope: ("Account" | "All")?)
	local defaults = self:ReadDefaults()

	scope = scope or "Account"

	if scope == "All" then
		defaults.All = name
	else
		defaults.Accounts[accountKey()] = name
	end

	self:WriteDefaults(defaults)
	self:Notify("Changed")
end

function Config:ClearDefault(scope: ("Account" | "All")?)
	self:SetDefault(nil, scope)
end

-- Returns the default config name for this account and which scope it came from
function Config:GetDefault(): (string?, ("Account" | "All")?)
	local defaults = self:ReadDefaults()
	local account = defaults.Accounts[accountKey()]

	if account and self:Exists(account) then
		return account, "Account"
	end

	if defaults.All and self:Exists(defaults.All) then
		return defaults.All, "All"
	end

	return nil, nil
end

-- Which scopes a specific config is the default for
function Config:DefaultScopes(name: string): { Account: boolean, All: boolean }
	local defaults = self:ReadDefaults()

	return {
		Account = defaults.Accounts[accountKey()] == name,
		All = defaults.All == name,
	}
end

function Config:LoadDefault(): (boolean, string?)
	local name = self:GetDefault()

	if not name then
		return false, "No default config"
	end

	return self:Load(name)
end

return Config
