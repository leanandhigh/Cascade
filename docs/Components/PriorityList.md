# PriorityList

An ordered list the player re-arranges with up / down arrows. Use it for farm or target priority: the first name has the highest priority.

```luau
local priority = box:PriorityList({
    Flag = "FarmPriority",
    Subtitle = "Top ON job farms first",
    Values = { "Evolution", "Farm", "Raid", "Infinite", "Material", "Craft", "Trials" },
})

cascade.Flags:OnChanged("FarmPriority", function(order)
    print(order[1]) -- do this job first
end)
```

| Property       | Type                                     | Description                                                              |
| -------------- | ---------------------------------------- | ------------------------------------------------------------------------ |
| `Values`       | `#!luau {string}`                        | The items, in their default order.                                       |
| `Value`        | `#!luau {string}?`                       | Current order. Unknown names are dropped, missing ones are added at the end. |
| `Subtitle`     | `#!luau string?`                         | Hint shown above the list.                                               |
| `Flag`         | `#!luau string?`                         | Saves the order in configs.                                              |
| `ValueChanged` | `#!luau (self, order: {string}) -> ()?`  | Called when the order changes.                                           |

Methods: `:GetOrder()`, `:SetOrder(order)`, `:MoveUp(name)`, `:MoveDown(name)`, `:IndexOf(name)`.
