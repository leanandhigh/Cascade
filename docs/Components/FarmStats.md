# FarmStats

A card of live stat tiles (icon, label, big value). Pair it with a [FarmHud](FarmHud.md) to show the same numbers in a floating overlay.

```luau
local stats = section:FarmStats({
    Title = "This session",
    Subtitle = "Resets when you rejoin",
    Columns = 3,
    Stats = {
        { Name = "Session", Icon = "timer", Type = "Timer" },
        { Name = "Wins", Icon = "trophy", Value = 0 },
        { Name = "Gems", Icon = "gem", Value = 0, Format = "short", PerHour = true },
        { Name = "Level", Icon = "chart-line", Value = function() return getLevel() end },
    },
})

stats:Increment("Wins")
stats:Increment("Gems", 250)
stats:Set("Level", 42)
stats:Reset()
```

Each stat:

| Field     | Description                                                                   |
| --------- | ----------------------------------------------------------------------------- |
| `Name`    | Key for `:Set` / `:Increment` / `:Get`.                                       |
| `Label`   | Shown text (defaults to `Name`).                                              |
| `Icon`    | Lucide name or asset id.                                                      |
| `Value`   | Number, string, or a function re-read every second.                           |
| `Type`    | `"Timer"` counts up from creation / `:Reset()` (`01:23:45`).                  |
| `Format`  | Numbers: `"comma"` (`1,234,567`, default), `"short"` (`1.2M`) or `"raw"`.     |
| `Prefix` / `Suffix` | Text around the value.                                              |
| `PerHour` | Also show the rate since the start (`3.1K/h`).                                |

Properties: `Title`, `Subtitle`, `Columns` (max, default `3`), `Collapsed`, `Collapsible`, `Stats`, `Source` (another FarmStats / FarmHud to share numbers with).

Methods: `:Set(name, value)`, `:Get(name)`, `:Increment(name, amount?)`, `:Reset(name?)`, `:Define(stat)`, `:Format(name)`.
