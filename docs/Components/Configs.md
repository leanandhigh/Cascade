# Configs

Every component created with a `Flag` is saved and loaded by the config system.

The config UI lives in the **Settings tab**, as a normal groupbox where everything is visible at once (no hidden menus):

- **Auto-load** row: which config loads on start (this account or all accounts)
- **Config** dropdown: pick a config
- **Name** field + **Create**, then **Save**, **Load**, **Refresh**, **Delete**
- **Auto-load for this account** / **Auto-load for all accounts** / **Remove auto-load**

When loading the default, this account's default wins over the all-accounts default.

```luau
window:Settings()                          -- full Settings tab, Configs included
-- or put just the Configs groupbox anywhere:
someTab:ConfigManager({ Side = "Right" })
```

## Window options

```luau
local window = app:Window({
    Config = {
        Folder = "MyHub",                 -- workspace folder
        SubFolder = tostring(game.PlaceId), -- optional, eg. one set of configs per game
        AutoLoad = true,                  -- load the default config on start
        Ignore = { "SomeFlag" },          -- flags that are never saved

        Saved = function(name) end,
        Loaded = function(name) end,
        Deleted = function(name) end,
    },
})
```

Pass `Config = false` to turn the config manager off.

## Flags

```luau
row:Right():Toggle({ Flag = "AutoFarm" })

cascade.Flags:Get("AutoFarm")
cascade.Flags:Set("AutoFarm", true)

-- Custom values
cascade.Flags:Register("Waypoints", {
    Get = function() return waypoints end,
    Set = function(value) waypoints = value end,
})
```

Values loaded before a flag exists are applied as soon as the flag is created, so autoload works no matter when your elements are made.

## Scripting

`window.Configs` exposes everything the panel does:

| Method                           | Description                                         |
| -------------------------------- | --------------------------------------------------- |
| `:List()`                        | Config names.                                       |
| `:Save(name)` / `:Load(name)`    | Save / load a config.                               |
| `:Delete(name)`                  | Delete a config.                                    |
| `:Rename(from, to)`              | Rename a config.                                    |
| `:SetDefault(name, scope)`       | `scope` is `"Account"` (default) or `"All"`.        |
| `:ClearDefault(scope)`           | Remove the default for a scope.                     |
| `:GetDefault()`                  | Returns `name, scope` of the active default.        |
| `:LoadDefault()`                 | Load the active default.                            |

Supported values: booleans, numbers, strings, tables, `EnumItem` (keybinds), `Color3`, `UDim2`, `Vector2`, `Vector3`.
