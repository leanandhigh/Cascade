---
name: cascade-mtwin
description: Rules, known pitfalls and fixed bugs for the Cascade UI library as used by MTwin HUB (Roblox Luau, branch claude/friendly-ride-yf5y59). Use whenever changing anything in src/, the example, or the dist build, so old bugs don't come back.
---

# Cascade / MTwin HUB: what to remember

Cascade is a Roblox Luau UI library (macOS style) extended into the MTwin HUB script-hub UI.
Read this before touching `src/`, `examples/full_example.luau` or `dist/dist.luau`.

## Project facts

- Work and push only on branch `claude/friendly-ride-yf5y59`. Never push to `main`.
- Hub name **MTwin HUB**. Logo asset id **77668182651543**, used as
  `rbxthumb://type=Asset&id=77668182651543&w=150&h=150`. Discord: **https://discord.gg/y35kyZM8sV**.
- Users load the committed build:
  - `loadstring(game:HttpGet("https://raw.githubusercontent.com/leanandhigh/Cascade/claude/friendly-ride-yf5y59/Loader.lua"))()`
    (Loader tries HttpGet, HttpGetAsync, request functions, httpget: some mobile executors lack HttpGet)
  - or directly `.../dist/dist.luau`.
  - raw.githubusercontent caches about 5 minutes: if "nothing changed" right after a push, wait and rejoin.
- **Always rebuild and commit `dist/dist.luau` after changing `src/`.** Users only run the dist.
  Build: `darklua process --config pipeline/darklua/stable.json src/init.luau out.luau`, then keep the
  12-line header of the old dist, add `__SH = { COMPINDEXES = {} }`, then the output.
- The user writes in English or Thai; answer in the language they used.
- When the user says "revert" / "nvm revert", undo exactly that change (git revert or remove the code)
  and keep unrelated fixes made in the same step. Don't argue.
- Keep `examples/full_example.luau` free of explanatory comments (only `--//` section headers).
- Commit messages end with the Co-Authored-By / Claude-Session lines from the system reminder.

## Architecture gotchas (cause real bugs)

- `creator.Create(class)(props)` returns a **proxy**; the real instance is `.__instance`.
  `FindFirstChild` returns **real Instances**. Reading `.__instance` (or any unknown member) on a real
  Instance **throws**: check `typeof(x) == "Instance"` first. (This once blanked every row title.)
- `__dynamicKeys` bind a property to a theme ValueState. `__contextKeys` are functions re-run only by
  `creator.RefreshContext()` after theme/accent changes. They are **not applied at creation**, so also
  set the initial value yourself.
- A dynamic key resets a property on every theme change; hand-painted colours must be re-applied with
  `task.defer` after the theme state changes.
- `binder.Wrap(properties, bindings, instance, excludeSets)`: a binding handler runs, then the raw value is
  stored, unless the key is in `excludeSets`. Use excludeSets when the handler normalises the value
  (PriorityList `Value`).
- The component wrapper (`src/components/init.luau`) copies **every component constructor** onto each
  returned object (`binder.Apply(components, result)`). Field names that equal a component name get
  overwritten: `Toggle`, `Button`, `Label`, `Tab`, `UpdateLog`, … Guard with a binding that ignores
  functions plus excludeSets (FarmStats `Toggle`, FarmHud `Button`), or rename (`LinkedToggle`, `HomeTab`, `Updates`).
- Wrapped component calls return `(result, final)`: wrap in parentheses inside `table.insert`.
- The wrapper also registers `Flag`s and adds `Disabled` / `DependsOn` / `ShowIf` / `:SetDisabled()` to every
  element (cover from `src/modules/disabled.luau`, in a Folder so layouts don't move it).

## Mobile (window drawn at UIScale 0.8)

- `AbsoluteSize` / `AbsolutePosition` / `TextBounds` are screen pixels. Offsets are not. **Divide by
  `utility.GetScale(instance)`** before writing measurements back as offsets (Section, Groupbox, Row,
  Slider, Columns, CardSection grid). Skip when scale < 0.05.
- The UIScale sits on the full-screen `Window` frame, so window **Position offsets are scaled too**:
  drag and resize deltas are divided by the scale.
- **Never tween the window UIScale** (old minimize did Scale→0). It changes every AbsoluteSize each frame and
  re-runs all layout listeners, which lagged badly on phones. Minimize = slide off-screen, then `Visible = false`.
- Pointer positions exclude the top-bar inset; AbsolutePosition in an IgnoreGuiInset gui may not. For
  drags use **deltas from the grab point** plus the element's own AbsolutePosition, relative to a
  full-screen layer frame (PriorityList ghost). For overlap checks use Position/AnchorPoint/size.
- Resize: invisible grip (20px, 26px mobile, **no arrow**: the user didn't want one) in the
  bottom-right corner, parented to the **Handles Folder**: the window body has a horizontal list layout,
  so a direct child gets laid out beside the sidebar. Start size from `Size` offsets, not AbsoluteSize.
- Mobile toggle default: top, 64px right of centre, y 22 (`UDim2.new(0.5, 64, 0, 22)`), under the window
  pill. The user rejected "move it under the farm HUD"; keep it simple.
- Narrow screens: Columns / Side groupboxes stack under `StackBelow` (480); rows shrink a slider (to 80px)
  before stacking; rows stack only when the **title text width** (TextBounds/scale + 16, 40..90) doesn't fit.
  Stacked controls go **under the text, left-aligned** (anchor 0, list Left, no left inset), never
  right-aligned under it. Measure the controls with the layout's AbsoluteContentSize (+11), not the
  frame's AbsoluteSize (full width while stacked, so it would never un-stack).
- Keybinds can't be bound without a keyboard: long-press opens the mode menu; keybind list entries are tappable.

## Fonts and text

- Font asset `rbxassetid://12187365364`. **Small text (≤ 12px) uses Medium weight**: Regular at
  11–12px looked like "the old font" to the user.
- `AutomaticSize` measures **before the custom font loads**, so pills end up cramped or off-centre and
  side-by-side labels overlap. Fix pills with `utility.FitText(label, paddingX, height)`
  (GetTextBoundsAsync). Put "value + rate" in **one RichText label** instead of two auto-sized labels.
- Card / section headers use the Groupbox metrics: title 15 SemiBold on a fixed 17px line, subtitle 12
  directly under it (1px gap), 14px side padding.
- Long texts that broke layouts: "Key: 3d …" on the profile card → key icon + `3d 03:59:52`; the version
  line → `Updated = "<date>"`.

## Performance (big hubs, many features)

- Tabs switch by **Visible**, all pages stay parented (like Obsidian). Re-parenting a page changed every
  descendant's AbsoluteSize at once and fired every layout listener: lag spike on tab click.
- Never scan `__SH.COMPINDEXES` (every component ever made) per event; use the container's own children.
- Batch layout work with `task.defer` flags (Page padding, ButtonRow, InfoCard columns).

## Text like Obsidian

- Titles, subtitles, labels and card subtitles are **one line, cut with "…"** (rows keep their height,
  nothing below moves down). `Wrap = true` (Row / TitleStack / Label) opts into wrapping, like Obsidian's DoesWrap.
- Slider rows: label on its own line, slider fills the row under it (number beside it), like Obsidian.
- Radio buttons are frames + UICorner + UIStroke (crisp at any scale), not images (they blurred when scaled).
- The user runs their own build, generated by `tools/cascade/sync.py` (mammothAT repo, not accessible here)
  from our dist plus text patches. Their screenshots can be **older than our fixes** until they re-sync:
  diff their file against our dist history to see the base commit and their patches.
- Their patches are now built in as options: `cascade.SetFont(family)` (modules/fonts; every element reads
  `require("@modules/fonts").Family`, never a literal font id), Window `Scale`, dropdowns open under the
  button by default (`OverLabel = true` for macOS style), Dashboard `Logs = false`, `settingsTab.Interface`,
  Configs box only with `window.Configs`, FarmStats `SessionText` / `StartedText` / text `Count` /
  `:SetSession(unix, label)`, FarmHud `Width` (300). Their icon URL swap stays in sync.py (changing the
  remote loadstring URL here was blocked).
- ButtonRow's divider is offset by its bottom padding (`UDim2.new(0, 0, 1, 10)`): padding on a frame also
  moves Folder children, so a divider at scale 1 sat under the buttons.

## "Use the full space" (recurring complaint, check every new layout)

- Never split a row with fixed percentages (45 % / 55 %) or fixed offsets that assume a width. Size the
  label from its real text (`TextBounds` / scale + a few px) and give the rest to the value
  (InfoCard, FarmHud rows, Row label vs controls).
- Pin trailing buttons to the edge (AnchorPoint 1, Position scale 1, in a Folder outside the list layout)
  instead of letting them follow a computed column (profile gear).
- Button labels never wrap ("Server / Hop"). ButtonRow measures labels, puts as many buttons per line
  as fit, and every line's buttons share that line's full width (line frames, balanced 2+1, 2+2…).
- When re-parenting into layout frames, move children **before** destroying old frames (destroying
  a frame destroys the buttons still inside).
- Deferred layout work must bail out if the element was destroyed (`body.Parent == nil`).

## Sidebar (leave as is)

- The user asked to **keep the original sidebar**: brand (padding 14, 30px logo, 10px gap), section
  label padding 8, Margins right padding 2. A re-alignment of brand / sections / equal tab gaps was reverted.

## Things the user asked for (keep them this way)

- Key countdown: ticking clock `3d 04:00:00` / `04:00:00`; keeps running while the page is hidden.
- Profile card: outside gaps equal too (body PaddingRight 8 because the sidebar Margins frame adds 2 on
  the right); even 10px gaps, 32px avatar, gear pinned right; card PaddingRight 5 (+ ~4px empty space
  around the glyph) so the gear glyph's right gap equals the avatar's left gap (measured from screenshots).
- Titlebar description copies on click/tap and is accent-blue when it is a link ("Copied!" for 1.2s);
  an invisible TextButton over it gives the hand cursor, and hover underlines it.
- Disabled / DependsOn / ShowIf on every element (cover in the groupbox colour blocks input).
- Update log: card header (title, subtitle, count, chevron), entry cards with centred Lucide badge + type tag.
- PriorityList: grid of numbered cards (`01`), **drag to reorder** (not a number picker, not arrows); card stays under the finger.
- FarmStats = **external full-screen "black screen"** (own ScreenGui, big timer only, no duplicate
  "Running" line, stat tiles, Materials with owned/gain, Close, 3D rendering off while shown).
- FarmHud = small draggable panel using the keybind-list surface (Card.Overlay), accent = `Controls.Selection`,
  status pill, optional button ("Black" opens FarmStats); example has a "Farm HUD" toggle and a plain "Black screen" toggle.
- Theme: no hard-coded colours. Use theme status colours for green/red; backdrop = darker theme
  background (grey in Light). Accent setting is a ColorPicker (`cascade.CustomAccent`).
- Keybind list: capitalised modes (`Toggle`, `Hold`), name sized to the space left by mode + key.
- Reverted on request, don't redo unless asked: dropdown option images; keybind-list restyle; mobile
  toggle "under the HUD"; sidebar brand / section re-alignment and equal tab gaps.

## Testing

- There is no Roblox in the container. A mock harness (Luau CLI + mock Instances) was used from the session
  scratchpad. It is not in the repo, so rebuild it if needed: run the example, then scripted checks for
  desktop and mobile (TouchEnabled, no mouse).
- The mock does not lay out or render: AbsoluteSize/Position are fixed defaults, Color3 has no font metrics.
  Set mock sizes in tests, and say plainly that visuals still need checking in-game.
- Mock gaps found so far (add if missing): `Vector2.zero`, `Color3:Lerp`, `TextService`.
- Before pushing: build dist, run desktop and mobile checks against both the unminified bundle and the minified dist.
