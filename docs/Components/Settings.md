# Settings

`window:Settings()` builds a complete Settings tab in one call. Everything is shown directly in the tab:

- **Interface** (left): theme, accent colour (a colour picker, any colour), menu keybind (show / hide the menu), show watermark, show keybind list, unload. Censor name / hide avatar stay on the profile card's settings button.
- **Configs** (right): the [ConfigManager](./Configs.md) groupbox

Theme, accent, menu keybind and the overlay toggles are saved in configs.

| Property      | Type                    | Description                                         |
| ------------- | ----------------------- | --------------------------------------------------- |
| `Section`     | `#!luau (string \| boolean)?` | The tab sits in its own sidebar group at the bottom, named `"General"` by default. A string renames it, `false` adds the tab without a group. |
| `Title`       | `#!luau string?`        | Tab title. Defaults to `"Settings"`.                |
| `Icon`        | `#!luau string?`        | Tab icon. Defaults to `"settings"`.                 |
| `MenuKey`     | `#!luau Enum.KeyCode?`  | Key that shows / hides the menu. Default RightControl. Ignored only while typing in a TextBox. |
| `Watermark`   | `#!luau Watermark?`     | Adds a "Show watermark" toggle.                     |
| `KeybindList` | `#!luau KeybindList?`   | Adds a "Show keybind list" toggle.                  |

It returns the tab, so you can add your own groupboxes to it.

```luau
local settings = window:Settings({
    Watermark = watermark,
    KeybindList = keybinds,
})

settings:Groupbox({ Side = "Left", Title = "Credits" }):Row({ Title = "Made by you" })
```

## Icons

Every `Icon` property accepts:

- **Lucide** names (`"house"`, `"swords"`, `"settings"`, see [lucide.dev/icons](https://lucide.dev/icons)), crisp sprite icons loaded from lucide-roblox-direct
- Cascade symbol names or values (`cascade.Symbols.gearshapeFill`)
- Asset ids (`123456`, `"rbxassetid://123456"`)

Lucide needs `game:HttpGet` (executors). Without it (Studio) Cascade falls back to its built-in symbols.
