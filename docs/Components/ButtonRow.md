# ButtonRow

A full-width row of buttons that share the width evenly. Use it for actions that have no label of their own: a `Row` with only buttons on the right leaves an empty gap on the left.

```luau
box:ButtonRow({
    Buttons = {
        { Label = "Teleport", State = "Primary", Pushed = function() end },
        { Label = "Reset", State = "Destructive", Pushed = function() end },
    },
})
```

| Property  | Type                        | Description                          |
| --------- | --------------------------- | ------------------------------------ |
| `Buttons` | `#!luau {ButtonProperties}?` | Buttons, left to right.             |
| `Spacing` | `#!luau number?`            | Gap between buttons. Default `8`.    |
| `Height`  | `#!luau number?`            | Button height. Default `28`.         |

`row:Add(buttonProperties)` adds another button; `row.Buttons` lists them.
