# Columns

`Columns` lays out components side by side. Each column is its own context, so anything created on it is parented to that column.

| Property  | Type             | Description                          |
| --------- | ---------------- | ------------------------------------ |
| `Count`   | `#!luau number?` | Number of columns. Defaults to `2`.  |
| `Spacing` | `#!luau number?` | Gap in pixels. Defaults to `9`.      |

| Method                  | Description                     |
| ----------------------- | ------------------------------- |
| `:Column(index)`        | Returns the column context.     |
| `:Left()` / `:Right()`  | First / last column.            |

```luau
local columns = tab:Columns({ Count = 3 })

columns:Column(1):Groupbox({ Title = "One" })
columns:Column(2):Groupbox({ Title = "Two" })
columns:Column(3):Groupbox({ Title = "Three" })
```
