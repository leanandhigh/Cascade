# Base Component

`BaseComponent` is the base class from which all Cascade components inherit. It provides core fields such as `Type`, `Theme`, and `Structures`.

---

## Summary

### Properties

| Property     | Type                                   | Description                                                                                                                                             |
| ------------ | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Type`       | `#!luau string`                        | **[Read-only]** Defines the Component's class.                                                                                                          |
| `Theme`      | `#!luau Theme`                         | **[Read-only]** Inherited theme from the calling component.                                                                                             |
| `Structures` | `#!luau {[string]: Instance or {any}}` | **[Read-only]** Table of defined component structures.                                                                                                  |
| `__instance` | `#!luau Instance`                      | **[Read-only]** Returns the unwrapped roblox instance of the component. Useful for interacting with Roblox API's that won't accept our wrapped instance |

!!! warning
    Note that to access a component's actual instance, you will need to index `__instance` on it, this will return the actual roblox object instead of a merged metatable with the custom object.

---

## Types

```luau
export type BaseComponent = {
    Type: string,
    Theme: Theme,
    Structures: { [string]: Instance | { any } },
}
```

## Disabled, DependsOn and ShowIf

Every element (rows, toggles, buttons, sliders, dropdowns, groupboxes…) accepts:

| Property    | Type                          | Description                                                                                       |
| ----------- | ----------------------------- | ------------------------------------------------------------------------------------------------- |
| `Disabled`  | `#!luau boolean?`             | Greys the element out and blocks clicks / taps / drags. Change it later with `:SetDisabled(bool)`. |
| `DependsOn` | `#!luau string or {Flag, Value}?` | Disabled until that flag is on (`"AutoFarm"`) or equals `Value` (`{ Flag = "Mode", Value = 2 }`). |
| `ShowIf`    | `#!luau string or {Flag, Value}?` | Hidden until that flag is on / equals `Value` (like Obsidian's dependency boxes).              |

```luau
box:Row({ Title = "Farm Distance", DependsOn = "AutoFarm" }):Right():Slider({ ... })
box:Row({ Title = "Wave Count", ShowIf = "AutoFarm" }):Right():Stepper({ ... })
box:ButtonRow({ Buttons = { { Label = "Server Hop", Disabled = true } } })
```
