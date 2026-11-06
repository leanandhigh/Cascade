# Change Log

## Unreleased

### Added

- `Window`: user profile card at the bottom-left of the sidebar, with a settings menu (Censor Name, Hide Avatar, custom `ProfileOptions`).
- `Window`: key duration for paid scripts (`KeyExpires`, `KeyDuration`, `KeyExpired`) with a live countdown on the profile card.
- `Window`: language picker next to the search field (`Languages`, `Language`, `LanguageChanged`).
- `Settings` tab (`window:Settings()`) with Interface and Configs groupboxes; `ConfigManager` groupbox (create, save, load, delete, auto-load for this account or all accounts), everything visible without menus.
- Lucide icons: every `Icon` accepts Lucide names (`"house"`), Cascade symbols or asset ids.
- `Dashboard` Information card (player, key time, game, executor, version); every update log entry is shown by default.
- `InfoCard` component.
- `Window`: minimize button in the titlebar; unload from the Settings tab (`CanUnload`, `Unloaded`, `window:Unload()`).
- Mobile support: auto-detected phones / tablets get a 0.8 scale, a window fitted to the screen and a round draggable logo toggle (`Mobile`, `MobileScale`, `MobileToggle`, `MobileToggleSide`); keybind list entries can be tapped.
- `cascade.Flags` and `cascade.Config`: any component created with `Flag = "..."` is saved by configs. `Flags:OnChanged(name, fn)` reacts to changes (clicks, `:Set`, config loads).
- More padding inside Button, TextField and PopUpButton; TextField is left-aligned with a fill and no longer clips its text.
- `Window` branding: `Logo`, `Brand`, `BrandSubtitle` (logo header at the top of the sidebar); with a brand the titlebar shows the selected tab (`TabTitles`).
- `Tab`: icon and title share one 20px box and are both centered on it (Obsidian's approach), 8px gap.
- Language picker: equal-width segments, visible pill, concentric corners.
- Config list marks the auto-load config.
- `ButtonRow`: full-width rows of equal buttons (used by the Configs groupbox).
- Divider under the brand header.

- `PriorityList`: grid of numbered cards you drag (mouse or touch) to reorder; the card stays under the pointer and the others make room while dragging. Saved in configs.
- `Loader.lua`: one-line loader that tries HttpGet, HttpGetAsync and the executor request functions.
- `FarmStats`: external full-screen stats screen (big session timer, stat tiles, materials with owned / gain, status pill); 3D rendering off while shown.
- `FarmHud`: floating draggable panel (timer, status, stat rows, gained items, optional button) that can share stats with `FarmStats`. Uses the keybind list / watermark surface and the theme accent; `FarmStats` backdrop and gain colours follow Dark / Light and the status colours.
- Pills (update log tags, counts, keybind keys, status) are sized from the real font metrics, so they no longer look cramped or off-centre; small labels use the Medium weight.
- `UpdateLog` redesign: title + subtitle header with count and collapse chevron, one card per entry with an icon badge and type tag.
- Window: visible resize grip in the bottom-right corner that works with touch (mobile resizing).
- `Settings`: the accent is a colour picker (any colour, `cascade.CustomAccent(color)`), saved as `UI_AccentColor`.
- `Columns` / `Groupbox` sides stack into one column on narrow windows (`StackBelow`, default 480).
- `Row`: when the controls leave no room for the label, they move onto their own line under it.
- Update log badges use centred Lucide icons (text glyphs only as a fallback).
- Key countdown shows a ticking clock (`3d 04:00:00`).

- `Disabled`, `DependsOn` and `ShowIf` on every element (greyed + locked, or hidden, depending on a toggle / flag); `:SetDisabled()`.
- Window: the titlebar description copies to the clipboard when clicked / tapped and is drawn in the accent when it's a link (`SubtitleCopy`).
- Dashboard: `Updated` (update date) replaces Version in the Information card.
- Profile card: key time shows a key icon and `3d 03:59:52` (no "Key:" word), so it fits.

- Text works like Obsidian: titles, subtitles and labels stay on one line (cut with "…") so long text no longer makes rows taller; `Wrap = true` opts into wrapping.
- Slider rows: label on its own line, the slider fills the row under it.

- `cascade.SetFont(family)`, Window `Scale`, PopUpButton `OverLabel` (lists open under the button by default), Dashboard `Logs = false`, `settingsTab.Interface`, FarmStats `SessionText` / `StartedText` / text counts / `:SetSession()`, FarmHud `Width`.

### Fixed

- Button rows: the divider below them was hidden under the buttons (it ignored the row's bottom padding).
- Lag spike when clicking a tab on big hubs: pages now stay parented and switch by visibility.
- Page spacing no longer scans every component in the UI each time a child is added.
- Radio buttons are drawn with frames (crisp at any UI scale) and the option name is clickable.
- Rows only stack when the label's actual title text doesn't fit (short labels like "Priority" / "Config" stay beside wide controls).
- Mobile (0.8 UI scale): sidebar sections, groupboxes and rows measured screen pixels as offsets, so tabs and groupboxes were clipped and labels overlapped controls; the resize handles shrank the window when grabbed and dragging moved slower than the finger; slider fills were short.
- Key countdown and Dashboard info stopped updating if their page wasn't on screen when created.
- Switching the theme back to Dark after Light did nothing (`app.Theme._id` kept the first theme's name).
- Real images (logo asset ids) on the watermark are no longer tinted with the accent colour.
- Changing the accent / theme now reaches state-dependent colours (toggles that are on, selected tabs, radio buttons…); they kept the old accent.
- Dropdown menus shrink again when their options change (the old height acted as a minimum).
- `Settings` tab sits in its own sidebar group at the bottom.
- Lucide icons load in the background (no HttpGet while building the UI) and are sized down to match the old symbols.

### Performance

- Closed dropdown menus no longer re-position themselves every time their button moves (window drag, scrolling), which forced extra layout passes every frame.

- Theme values only notify on real changes (thousands fewer updates on load).
- The window's layout fix no longer resizes every element twice in one frame; it nudges once and spreads a single pass over auto-sized elements across frames.
- New `ColorPicker` (30×18 swatch) (saturation / brightness, hue, optional transparency, hex / RGB, copy / paste; mouse and touch).
- New components: `Groupbox` (with `Side = "Left" | "Right"`), `Columns`, `Dashboard`, `UpdateLog`, `InviteCard`, `Watermark`, `KeybindList`.
- `Row`: `Title` / `Subtitle` properties create its TitleStack for you.
- `KeybindField`: `ToggleFlag` / `LinkedToggle` link a keybind to a toggle so its mode drives it (Toggle flips, Hold = on while held, Always = on); `IsActive`, `SetActive`, `ActiveChanged`.
- `KeybindList`: entry names size to the space left by the mode and key, so they never overlap.
- `KeybindField`: `KeybindList`, `KeybindName`, `KeybindMode` to show the bind in a `KeybindList`; right-click (long-press) menu to pick Toggle / Hold / Always or Remove the bind; the mode is saved in configs (`Flag .. "Mode"`).
- Themes: `Controls.Status` and `Controls.Card` keys.

### Changed

- `Window`: the macOS window control dots are hidden by default (`WindowControls = true` brings them back), the sidebar list moves up into that space.

## v1.4.0 (5/19/2026)

> Co-authored by @Androssy

### Added

- Added `cascade.AppRecorder` and `cascade.AppDump` for exporting Cascade app/component structure as JSON.
- Added a max length for `PopUpButton`, to where it will get truncated at.

### Fixed

- `Titlebar`: typo "ConerClipRight" -> "CornerClipRight" so
  structures.CornerClipRight isn't always nil
- `Notification`: topbar Visible checked properties.Icon but Icon is
  the content title icon, not the topbar one. should be AppIcon, to
  match the App/AppIcon bindings in init
- `Symbol`: Fixed a typo defining a theme key
- `Section`: Fixed leak in `Expand` cleaner, most connections were leaked.
- `Slider`: Added a guard when Minimum == Maximum

## v1.3.1 (5/18/2026)

### Fixed

- Fix dropdown menus `ResetOnSpawn`
- Fix dropdown menus not opening in some cases

## v1.3.0 (5/18/2026)

Co-authored-by: microwave.xyz <209287890+sysscan@users.noreply.github.com>

### Added

- Added a new component, [`ImageSurface`](docs\Components\ImageSurface.md)

### Changed

- Scrollbars UI-wide now use theme keys that change for light and dark mode
- Dropdown menus (`PopUpButton`'s, `PullDownButton`'s') now have appropriate behavior
  - `PopUpButton`: The menu will now expand in a position that alligns the current selected option with the component selection label perfectly
  - `PopUpButton` (Multi) & `PullDownButton`: The menu now opens Right-Alligned 6px below the component.

### Fixed

- Fixed a visual issue where dropdown menus when opened in some scenarios would have all options highlighted (accent color).
- Fixed a nil read error when setting .Value in `PopUpButton` and `PullDownButton`.

## v1.2.1 (5/1/2026)

- Fixed `Tab.Selected` property didn't deselect other tabs
- Types used a property `Page` which was inaccessible due to the `Page` component overwriting it, the docs now redirect to `Tab.Structures.Page`
- Fixed the `Page` type stating it returned a `Frame` instead of `ScrollingFrame`
- Updated to SF Symbols 7
- Added Properties to window: `CanExit`, `CanMinimize`, `CanZoom`
- Increased the title icon size in the `Notification` component from `13x13` to `18x18`
- Reworked `PageSection` component layouts. You will now be able to place components above, under, and in between page sections. Previously you couldn't put anything in between theme, due to PageSections having their own content container in each page.

## v1.2.0 (3/6/2026)

This update is a huge leap forward in terms of external usability and user customisability.

The main focus of this update is:

- The native support of using component's standalone
- The ability to register your own components

```diff
+ Added the ability to make custom components via `cascade.RegisterComponent`
+ Added the ability to natively make standalone components via `cascade.Component`
+ Expose cascade internal modules: `Creator`, `Binder`, `Components`

! Objects now return the actual instance via tuple when you call it. It is the second return.
! Button pushed animations now darken the button with an overlay instead of increasing shadow opacity
! Decreased the luminosity for most Accents, making the selected text easier to read
```

## v1.1.0 (3/4/2026)

```diff
+ Add theme accents: Blue, Graphite, Green, Orange, Pink, Purple, Red, Yellow
+ Add `Accent` property to `App` for setting and switching accent colors at runtime
+ Add `Notification` component with `Title`, `Subtitle`, `App`, `AppIcon`, `Icon`, `Duration`, and `Closed` properties
+ Add hover highlight to `PopUpButton` and `PullDownButton` menu options
+ Add default `Options` fallback for `PopUpButton`

! Removed `cascade.Window()` warning helper (use `app:Window()` directly)
! Removed hardcoded `TrackFill` color from dark theme slider (now driven by accent)
! Fixed `Tab` context key returning a broken `BackgroundColor3` function
! Fixed `Tab` type definition indentation in `types.luau`
! Fixed light theme `SwitchOn` hex casing inconsistency
! Internal theme refactor: themes now carry `_id` identifiers, `deepCopy` supports identifiers, and theme updates are handled by `updateThemes`/`parseAccent`
```

## v1.1.0-beta.1 (2/23/2026)

```diff
+ Add theme accents: Blue, Graphite, Green, Orange, Pink, Purple, Red, Yellow
+ Add `Accent` property to `App` for setting and switching accent colors at runtime
+ Add `Notification` component with `Title`, `Subtitle`, `App`, `AppIcon`, `Icon`, `Duration`, and `Closed` properties
+ Add hover highlight to `PopUpButton` and `PullDownButton` menu options
+ Add default `Options` fallback for `PopUpButton`

! Removed `cascade.Window()` warning helper (use `app:Window()` directly)
! Removed hardcoded `TrackFill` color from dark theme slider (now driven by accent)
! Fixed `Tab` context key returning a broken `BackgroundColor3` function
! Fixed `Tab` type definition indentation in `types.luau`
! Fixed light theme `SwitchOn` hex casing inconsistency
! Internal theme refactor: themes now carry `_id` identifiers, `deepCopy` supports identifiers, and theme updates are handled by `updateThemes`/`parseAccent`
```

## v1.0.1-beta.2 (2/9/2026)

```diff
+ Added warning if you call ':Window()' on the Cascade module instead of an Application for API conversion help.
+ Added `Maximum` property to `PopUpButton` (multi-select)
+ Added `Page` component
+ Added `Page` property to tabs to link a custom page
+ Added `:Navigate` Method to tabs to navigate between pages easily

! Internal & Pipeline changes
! Fixed section component returning type `Tab` instead of `Section`
! Slight visual changes to the push button component
```

## v1.0.1-beta.1 (12/2/2025)

```diff
+ Added warning if you call ':Window()' on the Cascade module instead of an Application for API conversion help.
+ Added `Maximum` property to `PopUpButton` (multi-select)

! Fixed section component returning type `Tab` instead of `Section`
! Slight visual changes to the push button component
```

## v1.0.0 (9/13/2025)

🥳 Officially released!

Thanks to those who used beta and reported bugs, everything is pretty bug-free.

```diff
+ Included .pcmp configuration in /pipeline, distribution key uses dotenv now

! Backend changes
! Changes and clarifications in installation docs
```

## v1.0.0-beta.7 (8/30/2025)

```diff
! Removed the `_P` PCMP build metadata global which was interfering with other builds that use PCMP. (It is now instead preserved in metadata tags.)
! Minor PR merge fixing spelling of "Luau"
```

## v1.0.0-beta.6 (7/19/2025)

```diff
! Fixed an issue where some first person games wouldn't let you move your camera around with a cascade window open. This was due to a modal frame.
! Fixed an issue where menus (pop-up menu, pull-down menu) would show behind the main window.
! Fixed an issue where the search field would not be visible at first.
```

## v1.0.0-beta.5 (7/17/2025)

```diff
+ Added pull-down buttons

! Fixed an issue where clicking off a menu (pull down buttons, pop up buttons) is offset around 30-40 pixels. This was fixed by counter-accounting for topbar inset.

? Possibly fixed an issue with the toggle's theme not using the correct theme on startup
```

## v1.0.0-beta.4 (7/15/2025)

```diff
+ Added pop-up buttons

- Removed a leftover print statement in symbols (Prints its style)

! Optimized toggles slightly by not putting them in a canvas groups, this should improve memory consumption.
! Changed the way a tab indent's itself, now instead of it's size being changed, the contents margins shrink to the right.
! Fixed unchanged statements in radio button groups (docs) from a copied component document in the docs.
! Fixed radio button groups having a default value if no value was given.
! Fixed accessory sizing behavior in rows (particularly the issue was for text fields, but this extends to all components.)
```

## v1.0.0-beta.3 (7/13/2025)

```diff
! Fixed errors on minimize if blur was disabled on startup.
! Fixed the search field not being set as non-visible if it was touching something on startup.

+ Added Auto-step when a stepper increment/decrement arrow is held.

? Possibly fixed an issue with the toggle's theme not using the correct theme on startup
```
