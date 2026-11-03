# Groupbox

A `Groupbox` groups related controls in a titled, collapsible box. Rows added to it get dividers, just like a [`Form`](./Form.md).

## Summary

### Properties

| Property      | Type                       | Description                                                                                         |
| ------------- | -------------------------- | --------------------------------------------------------------------------------------------------- |
| `Title`       | `#!luau string?`           | Header title.                                                                                       |
| `Subtitle`    | `#!luau string?`           | Smaller text under the title. `Description` is accepted as an alias.                               |
| `Icon`        | `#!luau string?`           | Accent-tinted icon left of the title (eg. `cascade.Symbols.cube`).                                  |
| `Side`        | `#!luau ("Left" \| "Right" \| 1 \| 2)?` | Places the box in an automatic two-column layout on the page.                          |
| `Expanded`    | `#!luau boolean?`          | Whether the content is shown. Defaults to `true`. `Collapsed = true` is accepted as an alias.       |
| `Collapsible` | `#!luau boolean?`          | Whether clicking the header collapses the box. Defaults to `true`.                                  |

### Events

| Event             | Signature                                                  |
| ----------------- | ---------------------------------------------------------- |
| `ExpandedChanged` | `#!luau ((self: Groupbox, expanded: boolean) -> ())?`      |

## Example

```luau
local box = tab:Groupbox({
    Side = "Left",
    Title = "Groupbox",
    Description = "boxes",
    Icon = cascade.Symbols.cube,
})

-- Rows accept Title / Subtitle directly
box:Row({ Title = "This is a toggle" }):Right():Toggle({ Flag = "MyToggle", Value = true })
box:Row({ Title = "Slider" }):Right():Slider({ Flag = "MySlider", Value = 0.5 })

tab:Groupbox({ Side = "Right", Title = "Dropdowns" })
```

!!! tip
    Need more than two columns, or columns outside of a page? Use [`Columns`](./Columns.md).
