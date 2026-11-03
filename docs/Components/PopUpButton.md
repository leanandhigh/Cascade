# PopUpButton

A `PopUpbutton` displays a menu of mutually exclusive/inclusive options.

![Component preview](../assets/component_popUpButton.png)

Each menu row is: tick (selected), image (optional), name. The selected option's image also shows on the button.

```luau
row:Right():PopUpButton({
    Options = {
        { Name = "Slime", Icon = "droplet" },
        { Name = "Dragon", Icon = 1234567 },
    },
    Value = 1,
})
```

## Summary

### Properties

| Property   | Type                          | Description                                                                                                                            |
| ---------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `Options`  | `#!luau {[number]: string or {Name, Icon}}?` | You can use this table to pre-define options. An option can be a name or `{ Name = "Slime", Icon = 1234567 }` to show an image in front of it (asset id, `rbxthumb://` or a Lucide name). Note that doing it this way will not give you access to the option instances themselves. |
| `Icons`    | `#!luau {[number or string]: any}?` | Images for the options by index or by name, instead of putting them in `Options`. |
| `Expanded` | `#!luau boolean?`             | Defines the state of the dropdown disclosure.                                                                                          |
| `Maximum`  | `#!luau number?`              | Maximum number of selectable options. Defaults to `1` (single-select).                                                                 |
| `Value`    | `#!luau number? or {number}?` | The selected index (single) or a table of selected indices when `Maximum > 1`.                                                         |
| `Anchor`   | `#!luau DropdownMenuAnchor?`  | Overrides where the menu opens.                                                                                                        |

[View all inherited from `BaseComponent`](./index.md/#properties)

[View all inherited from `TextButton`](https://create.roblox.com/docs/reference/engine/classes/TextButton#summary-properties)

### Methods

| Method   | Signature                              | Description                                                                                                                                                             |
| -------- | -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Option` | `#!luau (Name: string?, Icon: any?) -> TextButton` | Can be used to seperately create options, use this if you want to access the option instances themselves. An example of use would be a dynamically updating playerlist. |
| `Remove` | `#!luau (Index: number?) -> nil`       | Can be used to remove options from the pop-up menu, this automatically removes it from the options list as well.                                                        |

[View all inherited from `TextButton`](https://create.roblox.com/docs/reference/engine/classes/TextButton#summary-methods)

### Events

| Event          | Signature                                                             | Description                                                                        |
| -------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `ValueChanged` | `#!luau ((self: PopUpButton, value: number or {number}) -> unknown)?` | A Callback function that is triggered when the `Value` property has been modified. |

[View all inherited from `TextButton`](https://create.roblox.com/docs/reference/engine/classes/TextButton#summary-events)

## Types

```luau
type DropdownMenuAnchorConfig = {
    Object: GuiObject?,
    Element: GuiObject?,
    Label: GuiObject?,
    Option: number?,
    Offset: Vector2?,
    XOffset: number?,
    YOffset: number?,
}

type DropdownMenuAnchor = GuiObject | DropdownMenuAnchorConfig

type PopUpButtonProperties = TextButton & {
    Options: { [number]: string }?,
    Expanded: boolean?,
    Anchor: DropdownMenuAnchor?,
    Maximum: number?,
    Value: (number | { number })?,
    ValueChanged: ((self: PopUpButton, value: number | { number }) -> unknown)?,
}

type PopUpButton = BaseComponent & Components & PopUpButtonProperties & {
    Option: (Name: string?) -> TextButton,
    Remove: (Index: number?) -> nil,
}
```

### Function Signature

```luau
function(self, properties: PopUpButtonProperties?): PopUpButton
```

## Example

```luau
local popUpButton = row:Right():PopUpButton({
    Options = {
        "Item One",
        "Item Two",
    },
    ValueChanged = function(self, value: number)
        print("Value changed:", self.Options[value])
    end,
})

print(popUpButton:IsA("TextButton")) --> true
print(popUpButton.ClassName) --> "TextButton"
print(popUpButton.Type) --> "PopUpButton"

local itemThree = popUpButton:Option("Item Three")
popUpButton.Value = 3 --> Value changed: "Item Three"

print(itemThree.ClassName) --> "TextButton"
popUpButton:Remove(3)
```

## Multi-select Example

```luau
local multi = row:Right():PopUpButton({
    Options = {"One","Two","Three","Four"},
    Maximum = 3,
    ValueChanged = function(self, value)
        -- `value` is ALWAYS a table of indices when `Maximum > 1` even if only 1 value is selected.
        print("Selections:")
        for _, idx in ipairs(value or {}) do
            print(self.Options[idx])
        end
    end,
})

local five = multi:Option("Five")

multi.Value = {1, 3}
```
