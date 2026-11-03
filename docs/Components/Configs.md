# Configs

Every component created with a `Flag` is saved and loaded by the config system. The window shows a config bar in the titlebar: click it to open **Presets**.

- **+** creates a new config (`Unnamed0`, `Unnamed1`, ...) from the current values
- click a config's name to rename it
- **autoload** (circular arrows) sets it as the default **for this account** or **for all accounts**
- **save** overwrites it with the current values, **load** applies it
- **trash** deletes the selected config, search and sort filter the list

When loading the default, this account's default wins over the all-accounts default.

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

Pass `Config = false` to hide the config bar.

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
