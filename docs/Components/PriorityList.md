# PriorityList

An ordered list shown as a grid of numbered cards (`01  Auto Join Challenge  ⌄`). Click (tap) a card to open **Move to position** and pick its new number. The first item has the highest priority.

```luau
local priority = section:PriorityList({
    Flag = "JoinPriority",
    Title = "Join priority",
    Subtitle = "Top enabled route wins; routing repeats after every visit to the lobby.",
    Columns = 2,
    Values = { "Auto Join Challenge", "Auto Join Story / Inf", "Auto Infinity Castle", "Auto Join Dungeon" },
})

cascade.Flags:OnChanged("JoinPriority", function(order)
    print(order[1]) -- try this first
end)
```

| Property       | Type                                    | Description                                                                 |
| -------------- | --------------------------------------- | --------------------------------------------------------------------------- |
| `Values`       | `#!luau {string}`                       | The items, in their default order.                                          |
| `Value`        | `#!luau {string}?`                      | Current order. Unknown names are dropped, missing ones are added at the end. |
| `Title`        | `#!luau string?`                        | Card header. Without `Title` / `Subtitle` the cards sit straight in the parent. |
| `Subtitle`     | `#!luau string?`                        | Muted text under the title.                                                 |
| `Columns`      | `#!luau number?`                        | Max columns (default `2`). Narrow windows / phones use fewer.                 |
| `Collapsed`    | `#!luau boolean?`                       | Start closed; click the header to toggle.                                   |
| `PickerTitle`  | `#!luau string?`                        | Picker heading. Default `"Move to position"`.                               |
| `Flag`         | `#!luau string?`                        | Saves the order in configs.                                                 |
| `ValueChanged` | `#!luau (self, order: {string}) -> ()?` | Called when the order changes.                                              |

Methods: `:GetOrder()`, `:SetOrder(order)`, `:MoveTo(name, position)`, `:MoveUp(name)`, `:MoveDown(name)`, `:IndexOf(name)`, `:OpenPicker(name)`, `:ClosePicker()`.
