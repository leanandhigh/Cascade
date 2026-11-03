# FarmStats

A full-screen farm stats screen in its own ScreenGui (outside the window): a black backdrop with one card showing the logo, title, a status pill, a big session timer, stat tiles and a materials grid (owned count + gain). The game behind an opaque screen doesn't need drawing, so 3D rendering is turned off while it's shown and back on when it closes (or the UI unloads).

```luau
local farmStats = app:FarmStats({
    Title = "MTwin HUB",
    Subtitle = "Anime Adventures",
    Icon = LOGO,
    Status = "Online",
    Stats = {
        { Name = "Level", Value = 225 },
        { Name = "Money", Value = 8433620 },
        { Name = "Wins", Value = 0, Icon = "trophy" },
        { Name = "Gems", Value = 33125, Format = "short", PerHour = true },
    },
    Materials = {
        { Name = "Gold Ore", Count = 1840, Gain = 120, Icon = 1234567 },
    },
})

farmStats:Show()
farmStats:Increment("Wins")
farmStats:UpdateMaterial("Gold Ore", 1900, 60)
farmStats:SetStatus("Farming", "Added")
```

| Property         | Type                        | Description                                                                 |
| ---------------- | --------------------------- | --------------------------------------------------------------------------- |
| `Title` / `Subtitle` | `#!luau string?`        | Header text.                                                                |
| `Icon`           | `#!luau any?`               | Logo in the tile (asset id / `rbxthumb` / Lucide).                          |
| `Status`         | `#!luau string?`            | Status pill text (default `"Online"`). `StatusKind` / `StatusColor` colour the dot. |
| `Stats`          | `#!luau {Stat}?`            | Stat tiles (up to 4 per row). Same stat format as below.                    |
| `Materials`      | `#!luau {Material}?`        | `{ Name, Count, Gain, Icon }`; gain shows as a green `+N` pill.             |
| `Footer`         | `#!luau string?`            | Hint under the card.                                                        |
| `Disable3D`      | `#!luau boolean?`           | `false` keeps the 3D world drawing while shown.                             |
| `Keep3DOff`      | `#!luau (() -> boolean)?`   | Return `true` to leave 3D off on close (your own "Disable 3D" setting).     |
| `Visible`        | `#!luau boolean?`           | Start shown.                                                                |
| `VisibleChanged` | `#!luau (self, visible) -> ()?` | Called on show / hide (eg. the Close button), to sync a toggle.         |

Stat fields: `Name`, `Label`, `Icon`, `Value` (number, string or function re-read every second), `Format` (`"comma"` default, `"short"`, `"raw"`), `Prefix`, `Suffix`, `PerHour` (adds a rate).

Methods: `:Show()`, `:Hide()`, `:Toggle()`, `:SetVisible(bool)`, `:IsVisible()`, `:Set(name, value)`, `:SetStats({ name = value })`, `:Get(name)`, `:Increment(name, amount?)`, `:SetMaterials(list)`, `:UpdateMaterial(name, count?, gain?, icon?)`, `:SetStatus(text, kind or Color3)`, `:Reset()` (new session), `:Destroy()`.

Pass the screen to a [FarmHud](FarmHud.md) as `Source` to show the same stats in the small overlay.
