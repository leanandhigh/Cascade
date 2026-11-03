# ColorPicker

A colour swatch that opens a picker: saturation / brightness square, hue bar, optional transparency bar, hex and RGB fields, and copy / paste between pickers. Works with mouse and touch. Layout follows Obsidian's colour picker.

```luau
row:Right():ColorPicker({
    Flag = "EspColor",                    -- saved in configs
    Value = Color3.fromRGB(0, 255, 140),
    Transparency = 0,                     -- optional: shows the transparency bar
    Title = "ESP Color",                  -- optional title in the picker
    ValueChanged = function(self, color, transparency) end,
})

cascade.Flags:OnChanged("EspColor", function(color) print(color:ToHex()) end)
```

| Property       | Type               | Description                                                |
| -------------- | ------------------ | ---------------------------------------------------------- |
| `Value`        | `#!luau Color3?`   | The colour.                                                |
| `Transparency` | `#!luau number?`   | 0 (solid) to 1. Giving a number shows the transparency bar. |
| `Title`        | `#!luau string?`   | Title shown at the top of the picker.                      |
| `Flag`         | `#!luau string?`   | Saves the colour in configs.                               |

Methods: `:Open()`, `:Close()`. The `Flag` saves the colour; `Transparency` is not part of the saved value.
