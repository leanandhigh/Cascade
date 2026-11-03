# FarmHud

A small floating card with farm status and stats, visible while the menu is hidden. Drag it with the mouse or a finger.

```luau
local hud = app:FarmHud({
    Title = "MTwin HUB",
    Icon = LOGO,
    Source = stats,                       -- a FarmStats: same numbers
    Only = { "Session", "Wins", "Gems" }, -- optional subset
    StatusFlag = "AutoFarm",              -- "Farming" / "Idle" from that toggle
})

hud:SetStatus("Joining raid", "Changed")
```

| Property     | Type                 | Description                                                         |
| ------------ | -------------------- | ------------------------------------------------------------------- |
| `Title`      | `#!luau string?`     | Header text.                                                        |
| `Icon`       | `#!luau string?`     | Logo (keeps its colours) or Lucide icon (accent).                   |
| `Source`     | `#!luau FarmStats?`  | Share stats with a FarmStats card.                                  |
| `Stats`      | `#!luau {Stat}?`     | Its own stats (same format as FarmStats) when there's no `Source`.  |
| `Only`       | `#!luau {string}?`   | Which stats to show.                                                |
| `StatusFlag` | `#!luau string?`     | Shows `StatusOn` (default `"Farming"`) / `StatusOff` (`"Idle"`).    |
| `Position`   | `#!luau UDim2?`      | Default top-right.                                                  |
| `Visible`    | `#!luau boolean?`    | Show / hide. `window:Settings({ FarmHud = hud })` adds a toggle.    |

Methods: `:SetStatus(text, kind?)` (`kind`: `"Added"` green, `"Changed"` orange, `"Removed"` red, `"Info"` blue), `:Set`, `:Get`, `:Increment`, `:Reset`.
