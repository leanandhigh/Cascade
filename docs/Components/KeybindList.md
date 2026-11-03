# KeybindList

A draggable overlay that lists keybinds and whether they are active.

| Property       | Type              | Description                                 |
| -------------- | ----------------- | ------------------------------------------- |
| `Title`        | `#!luau string?`  | Defaults to `"Keybinds"`.                   |
| `HideInactive` | `#!luau boolean?` | Only show active keybinds.                  |
| `Draggable`    | `#!luau boolean?` | Defaults to `true`.                         |

Methods: `:Add({ Name, Key, Mode, Active })` returns an entry (`entry.Active`, `entry.Key`, `entry.Name`, `entry:Toggle()`, `entry:Remove()`), `:Clear()`.

## Linking a KeybindField

Pass the list to a [`KeybindField`](./KeybindField.md) and it keeps the key and active state in sync:

```luau
local keybinds = app:KeybindList()

row:Right():KeybindField({
    Flag = "FlyKey",
    Value = Enum.KeyCode.F,
    KeybindList = keybinds,
    KeybindName = "Fly",
    KeybindMode = "Toggle", -- "Toggle" | "Hold" | "Always"
})
```

`keybindField:IsActive()` returns the current state.
