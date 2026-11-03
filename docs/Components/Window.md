# Window

`Window` is a high-level container that handles all base interaction with the user for you. Usually this is the first component called and most components stem from here.

![Component preview](../assets/component_window.png)

## Summary

### Properties

| Property      | Type              | Description                                                                        |
| ------------- | ----------------- | ---------------------------------------------------------------------------------- |
| `Searching`   | `#!luau boolean?` | Shows a text field in the title bar which can be used to search pages for content. |
| `Draggable`   | `#!luau boolean?` | Enables window dragging via mouse or touch device.                                 |
| `Resizable`   | `#!luau boolean?` | Enables resizing via sides or corners.                                             |
| `CanExit`     | `#!luau boolean?` | Enables the window exit control (close). Defaults to `true`.                       |
| `CanMinimize` | `#!luau boolean?` | Enables the window minimize control. Defaults to `true`.                           |
| `CanZoom`     | `#!luau boolean?` | Enables the window zoom/maximize control. Defaults to `true`.                      |
| `Title`       | `#!luau string?`  | Title displayed in the content titlebar.                                           |
| `Subtitle`    | `#!luau string?`  | Subtitle displayed under the title. Will be visually disabled if not defined.      |
| `Maximized`   | `#!luau boolean?` | Should the window be maximized by default?                                         |
| `Minimized`   | `#!luau boolean?` | Should the window be minimized by default?                                         |
| `Dropshadow`  | `#!luau boolean?` | Enables a dropshadow effect on the window.                                         |
| `UIBlur`      | `#!luau boolean?` | Applies a background blur effect to the sidebar.                                   |

#### Sidebar, profile & key

| Property                | Type                                    | Description                                                                                          |
| ----------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `WindowControls`        | `#!luau boolean?`                       | Shows the macOS close / minimize / zoom dots. Defaults to `false`, the sidebar uses that space.       |
| `CanUnload`             | `#!luau boolean?`                       | Shows the unload (power) button in the titlebar. Defaults to `true`.                                 |
| `Unloaded`              | `#!luau ((self: Window) -> ())?`        | Called when the UI is unloaded (button or `window:Unload()`). Disconnect your stuff here.           |
| `UserProfile`           | `#!luau boolean?`                       | Shows the user card at the bottom-left of the sidebar. Defaults to `true`.                          |
| `ProfileName`           | `#!luau string?`                        | Name on the card. Defaults to the local player's display name.                                       |
| `ProfileSubtitle`       | `#!luau string?`                        | Text under the name when no key is set. Defaults to `"Account"`.                                     |
| `ProfileImage`          | `#!luau string?`                        | Avatar image. Defaults to the local player's headshot.                                               |
| `CensorName`            | `#!luau boolean?`                       | Masks the name (`u***1`). Also toggled from the card's settings button.                              |
| `HideAvatar`            | `#!luau boolean?`                       | Hides the avatar. Also toggled from the card's settings button.                                      |
| `ProfileOptions`        | `#!luau {ProfileOption}?`               | Extra items for the settings menu: `{ Title, Icon?, Checked?, Changed? }` or `{ Title, Pushed }`.    |
| `ProfileSettingChanged` | `#!luau ((self, setting: string, value: boolean) -> ())?` | Called when `CensorName` / `HideAvatar` change.                                  |
| `KeyExpires`            | `#!luau (number \| string)?`            | Unix timestamp the key expires at, `"Lifetime"`, or any text. Shows a live countdown on the card.    |
| `KeyDuration`           | `#!luau number?`                        | Seconds until the key expires (sets `KeyExpires` for you).                                           |
| `KeyExpired`            | `#!luau ((self: Window) -> ())?`        | Called once when the countdown hits zero.                                                            |

#### Language & configs

| Property          | Type                                            | Description                                                                                  |
| ----------------- | ----------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `Languages`       | `#!luau {string}?`                              | Language codes shown next to the search field, eg. `{ "EN", "TH" }`.                        |
| `Language`        | `#!luau string?`                                | Selected language. Defaults to the first one.                                                |
| `LanguageChanged` | `#!luau ((self: Window, language: string) -> ())?` | Called when the language changes. Cascade does not translate anything, update your texts here. |
| `Config`          | `#!luau (ConfigOptions \| boolean)?`            | Config manager options (`false` turns it off). The UI is in the Settings tab, see [Configs](./Configs.md).                           |

`window.Configs` is the window's config manager, `window:Settings()` builds the Settings tab, `window:KeyStatus()` / `window:DisplayName()` return what the profile card shows, and `window:Unload()` unloads the whole UI.

[View all inherited from `BaseComponent`](./index.md/#properties)

[View all inherited from `Frame`](https://create.roblox.com/docs/reference/engine/classes/Frame#summary-properties)

### Methods

[View all inherited from `Frame`](https://create.roblox.com/docs/reference/engine/classes/Frame#summary-methods)

### Events

[View all inherited from `Frame`](https://create.roblox.com/docs/reference/engine/classes/Frame#summary-events)

## Types

```luau
type WindowProperties = Frame & {
    Searching: boolean?,
    Draggable: boolean?,
    Resizable: boolean?,
    Title: string?,
    Subtitle: string?,
    CanExit: boolean?,
    CanMinimize: boolean?,
    CanZoom: boolean?,
    Maximized: boolean?,
    Minimized: boolean?,

    Dropshadow: boolean?,
    UIBlur: boolean?,
}

type Window = BaseComponent & Components & WindowProperties
```

### Function Signature

```luau
function(self, properties: WindowProperties?): Window
```

## Example

```luau
local window = app:Window({
    Title = "Cascade",
    Subtitle = "This is my subtitle.",
})

print(window:IsA("Frame")) --> true
print(window.ClassName) --> "Frame"
print(window.Type) --> "Window"
```
