# Dashboard

`Dashboard` creates a home tab with an update log and copyable community links. It is built from two components you can also use on their own: `UpdateLog` and `InviteCard`.

## Dashboard

| Property     | Type                         | Description                                                     |
| ------------ | ---------------------------- | --------------------------------------------------------------- |
| `Title`      | `#!luau string?`             | Tab title. Defaults to `"Dashboard"`.                           |
| `Icon`       | `#!luau string?`             | Tab icon. Defaults to `houseFill`.                              |
| `Selected`   | `#!luau boolean?`            | Select the tab. Defaults to `true`.                             |
| `Version`    | `#!luau string?`             | Shown under the "Updates" header.                               |
| `Logs`       | `#!luau {UpdateLogEntry}?`   | Update log entries.                                             |
| `Preview`    | `#!luau number?`             | How many entries are visible before "View all". Default `5`.    |
| `LinksTitle` | `#!luau string?`             | Header above the links.                                         |
| `Discord`    | `#!luau string?`             | Shortcut for a Discord `InviteCard`.                            |
| `Links`      | `#!luau {InviteCardProperties}?` | Extra link cards.                                           |

The returned object forwards everything to its tab, so you can keep adding components (`dashboard:PageSection(...)`). Use `dashboard:Log(entry)` to add update log entries later.

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
| `Title`    | `#!luau string?`           | Defaults to `"Update Logs"`.                  |
| `Entries`  | `#!luau {UpdateLogEntry}?` | `"+ text"`, `"~ text"`, `"- text"`, `"! text"` or `{ Type, Text }` where `Type` is `Added`, `Changed`, `Fixed`, `Removed` or `Info`. |
| `Preview`  | `#!luau number?`           | Visible entries while collapsed.              |
| `Expanded` | `#!luau boolean?`          | Show every entry.                             |

Methods: `:Add(entry)`, `:Clear()`.

## InviteCard

| Property   | Type             | Description                                          |
| ---------- | ---------------- | ---------------------------------------------------- |
| `Title`    | `#!luau string?` | Defaults to `"Discord"`.                             |
| `Subtitle` | `#!luau string?` | Defaults to `"Click the invite to copy."`.           |
| `Invite`   | `#!luau string?` | The text copied to the clipboard when clicked.       |
| `Icon`     | `#!luau string?` | Card icon.                                           |
| `Copied`   | `#!luau ((self, invite: string, copied: boolean) -> ())?` | Called on click. |
