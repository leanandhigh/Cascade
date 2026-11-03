# Watermark

A draggable overlay pill showing your title, FPS, ping, the time and any custom text. Create it on the app.

| Property    | Type              | Description                               |
| ----------- | ----------------- | ----------------------------------------- |
| `Title`     | `#!luau string?`  | Bold first segment.                       |
| `Text`      | `#!luau string?`  | Custom segment, can be changed any time.  |
| `Icon`      | `#!luau string?`  | Optional accent icon.                     |
| `ShowFPS`   | `#!luau boolean?` | Defaults to `true`.                       |
| `ShowPing`  | `#!luau boolean?` | Defaults to `true`.                       |
| `ShowTime`  | `#!luau boolean?` | Defaults to `true`.                       |
| `Draggable` | `#!luau boolean?` | Defaults to `true`.                       |
| `Visible`   | `#!luau boolean?` | Show / hide.                              |

```luau
local watermark = app:Watermark({ Title = "My Hub", Text = "Premium" })

watermark.Text = "Farming..."
```
