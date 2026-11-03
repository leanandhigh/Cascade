# Dashboard

`Dashboard` creates a home tab that shows everything up front: an **Information** card (player, key time left, game, executor, version), the full update log and copyable community links. It is built from two components you can also use on their own: `UpdateLog` and `InviteCard`.

## Dashboard

| Property     | Type                         | Description                                                     |
| ------------ | ---------------------------- | --------------------------------------------------------------- |
| `Title`      | `#!luau string?`             | Tab title. Defaults to `"Dashboard"`.                           |
| `Icon`       | `#!luau string?`             | Tab icon. Defaults to `houseFill`.                              |
| `Selected`   | `#!luau boolean?`            | Select the tab. Defaults to `true`.                             |
| `Version`    | `#!luau string?`             | Shown under the "Updates" header.                               |
| `Logs`       | `#!luau {UpdateLogEntry}?`   | Update log entries.                                             |
| `Preview`    | `#!luau number?`             | Collapse the log behind "View all" after this many entries. By default every entry is shown. |
| `Info`       | `#!luau (boolean \| {InfoItem})?` | Extra rows for the Information card, or `false` to hide it. |
| `LinksTitle` | `#!luau string?`             | Header above the links.                                         |
| `Discord`    | `#!luau string?`             | Shortcut for a Discord `InviteCard`.                            |
| `Links`      | `#!luau {InviteCardProperties}?` | Extra link cards.                                           |

The returned object forwards everything to its tab, so you can keep adding components (`dashboard:PageSection(...)`). Use `dashboard:Log(entry)` to add update log entries later. `dashboard.Updates` is the `UpdateLog`, `dashboard.HomeTab` the tab and `dashboard.Links` the link cards.

```luau
local dashboard = window:Dashboard({
    Version = "1.0.16",
    Logs = {
        "+ More maps in Dungeon and Macro settings",       -- Added
        "~ Card priority could stop the script from loading", -- Changed / Fixed
        "- Old macro recorder",                            -- Removed
        { Type = "Info", Text = "Server maintenance on Friday" },
    },
    LinksTitle = "My Hub \\ My Game",
    Discord = "https://discord.gg/xxxxxx",
})
```

## UpdateLog

| Property   | Type                       | Description                                   |
| ---------- | -------------------------- | --------------------------------------------- |
| `Title`    | `#!luau string?`           | Defaults to `"Update log"` (`"What's new"` on the Dashboard). |
| `Subtitle` | `#!luau string?`           | Muted text under the title (the Dashboard puts the version here). |
| `Entries`  | `#!luau {UpdateLogEntry}?` | `"+ text"`, `"~ text"`, `"- text"`, `"! text"` or `{ Type, Text, Tag? }` where `Type` is `Added`, `New`, `Improved`, `Changed`, `Fixed`, `Removed`, `Info` or `Note`. Each entry is a card with an icon badge and a type tag (`Tag` overrides the tag text). |
| `Preview`  | `#!luau number?`           | Entries shown before "View all" (default: all). |
| `Expanded` | `#!luau boolean?`          | Show every entry.                             |
| `Collapsed`| `#!luau boolean?`          | Start closed (click the header to toggle).    |

Methods: `:Add(entry)`, `:Clear()`.

## InviteCard

| Property   | Type             | Description                                          |
| ---------- | ---------------- | ---------------------------------------------------- |
| `Title`    | `#!luau string?` | Defaults to `"Discord"`.                             |
| `Subtitle` | `#!luau string?` | Defaults to `"Click the invite to copy."`.           |
| `Invite`   | `#!luau string?` | The text copied to the clipboard when clicked.       |
| `Icon`     | `#!luau string?` | Card icon.                                           |
| `Copied`   | `#!luau ((self, invite: string, copied: boolean) -> ())?` | Called on click. |
