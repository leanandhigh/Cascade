# FarmHud

A small floating panel over the game: caption with an optional button, a big session timer with a status pill, stat rows and a list of gained items. Drag it with the mouse or a finger.

```luau
local hud = app:FarmHud({
    Title = "MTwin HUB",
    Icon = LOGO,
    Source = farmStats,                 -- same stats as the FarmStats screen
    Only = { "Wins", "Gems" },
    StatusFlag = "AutoFarm",            -- "Farming" / "Idle"
    Button = { Text = "Black", Callback = function() farmStats:Toggle() end },
})

hud:SetItems({ { Name = "Gold Ore", Amount = 4 }, { Name = "Star Fruit", Amount = 1 } })
```

| Property     | Type                 | Description                                                      |
| ------------ | -------------------- | ---------------------------------------------------------------- |
| `Title`      | `#!luau string?`     | Caption (shown in capitals).                                     |
| `Icon`       | `#!luau any?`        | Logo (keeps its colours) or Lucide icon (accent).                |
| `Source`     | `#!luau FarmStats?`  | Share stats with the FarmStats screen.                           |
| `Stats`      | `#!luau {Stat}?`     | Its own stats when there's no `Source`.                          |
| `Only`       | `#!luau {string}?`   | Which stats to show as rows.                                     |
| `StatusFlag` | `#!luau string?`     | Shows `StatusOn` (default `"Farming"`) / `StatusOff` (`"Idle"`). |
| `Button`     | `#!luau {Text, Callback}?` | Small button in the header.                                 |
| `Timer`      | `#!luau boolean?`    | `false` hides the big timer.                                     |
| `MaxItems`   | `#!luau number?`     | Items shown before "+N more" (default 6).                        |
| `Position`   | `#!luau UDim2?`      | Default top-right.                                               |
| `Visible`    | `#!luau boolean?`    | `window:Settings({ FarmHud = hud })` adds a toggle.              |

Methods: `:SetStatus(text, kind?)`, `:SetItems(list)`, `:SetButton(text, callback)`, `:ResetTimer()`, `:SetElapsed(seconds)`, `:Set` / `:SetRow`, `:Get`, `:Increment`, `:Reset`.
