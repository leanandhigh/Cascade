# InfoCard

A card listing information rows, always visible. The Dashboard uses one for player, key time, game, executor and version.

```luau
tab:InfoCard({
    Title = "Information",
    Icon = "info",
    Items = {
        { Label = "Version", Value = "1.0.16" },
        { Label = "Key", Value = function() return window:KeyStatus() end }, -- refreshed every second
    },
})
```

A `Value` function may return `text` or `text, colorPair` (eg. `self.Theme.Controls.Status.Added`). Methods: `:Add(item)`, `:Refresh()`.
