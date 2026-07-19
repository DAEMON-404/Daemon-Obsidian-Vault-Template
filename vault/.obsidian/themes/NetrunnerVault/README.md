# NetrunnerVault Theme · v3

A standalone **Rosé Pine Editorial** theme for this vault. Light mode uses Rosé Pine Dawn as the primary reading experience; dark mode uses Rosé Pine Moon.

The theme is designed for long technical sessions: quiet prose surfaces, clear hierarchy, compact metadata, and dark terminal treatment reserved for executable code.

## Fonts

Loaded automatically through Google Fonts:

- **Newsreader** — note titles and major headings
- **Space Grotesk** — body and interface text
- **JetBrains Mono** — code, properties, badges, and compact data labels

## Activate

Open **Settings → Appearance → Themes → NetrunnerVault**. Choose **Light** for the primary Dawn palette. The vault's `appearance.json` already selects this theme and light mode.

## Note classes

- `editorial` narrows a note to a comfortable reading measure and turns unlabelled ASCII/diagram blocks into quiet paper figures.
- `dashboard` widens the canvas for Dataview tables, statistics, and navigation grids.
- Dashboards can use `[!dashboard]` for an orientation panel and `[!grid]` for a responsive link-card list.

Both classes can be listed together in frontmatter:

```yaml
cssclasses:
  - dashboard
  - editorial
```

## Analyst Workspace

The main dashboard uses the Analyst Workspace system: Dawn remains the reading canvas, while one Moon active-context panel marks the note worth resuming. Cyberpunk detail is intentionally restrained—technical micro-labels, evidence rails, clipped focus-panel corners, and a faint static circuit grid.

Reusable classes:

- `nv-workspace-bar` — compact vault identity and known page context.
- `nv-focus-panel` — the single Moon active-context surface.
- `nv-review-grid` / `nv-review-stat` — trustworthy live maintenance counts.
- `nv-empty-state` — useful guidance when a query has no results.

Dashboards can add an optional accent class alongside `dashboard` and `editorial` to tint a section (for example `domain-university`, `domain-cybersecurity`, `domain-personal`, `domain-tools`). These are optional — the base `dashboard` class is all you need.

Core Bases surfaces inherit the same paper, border, type, and focus treatment; no Bases database is created by the theme.

### Automatic note banners

New notes use the same live Moon title card shown on the main dashboard. `00Meta/Views/NoteBanner/view.js` reads the current filename, folder, modification time, type, and status; moving or renaming the note updates the banner automatically.

- Plain **New Note** files receive `00Meta/Templates/Default-Note-Template.md` through Templater's root `/` Folder Templates rule.
- Specialized templates add `note-banner` and call the same Dataview view once.
- Reading view hides the duplicate native title and properties panel; metadata remains editable in Live Preview/source mode.
- Dataview JavaScript must remain enabled for the live banner to render.

Templater's `data.json` is intentionally local under this repository's ignore policy. On another device or checkout, enable **Trigger Templater on new file creation**, enable **Folder Templates**, and map `/` to `00Meta/Templates/Default-Note-Template.md`.

## What it styles

- Focused note widths and a wider responsive dashboard canvas
- Editorial title and heading hierarchy without animated carets or decorative heading glyphs
- Soft Dawn callouts with a semantic evidence rail
- Dark Rosé Pine terminal windows for fenced code
- Tables, Dataview results, properties, tags, links, embeds, checkboxes, and blockquotes
- Optional badge pills, stat cards, and completion bars
- File explorer, tabs, prompts, status bar, scrollbars, and graph view
- Keyboard focus, mobile layouts, reduced motion, and print output

## Palette

Dawn: base `#faf4ed` · paper `#fffaf3` · text `#575279` · iris `#907aa9` · pine `#286983` · foam `#56949f` · gold `#ea9d34` · rose `#d7827e` · love `#b4637a`.

## CSS snippets

Only `floating-search-bar` is enabled. Older colour, card, callout, and code-block snippets remain in `.obsidian/snippets/` but stay disabled to avoid competing with the theme.
