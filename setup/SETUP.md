# Setup

This folder contains the vault initialiser scripts and the plugin manifest list.

- `setup.sh` — macOS / Linux (bash)
- `setup.ps1` — Windows (PowerShell 5+ or PowerShell 7+)
- `plugins.txt` — the community-plugin list, used by both scripts

## What the script does

1. Copies `vault/` (the template) to a target directory you choose.
2. Prompts for four identity values and rewrites the placeholder tokens
   throughout the copied notes and templates.
3. Optionally downloads the community plugins from their GitHub releases.
4. Prints the remaining manual steps to run inside Obsidian.

The script never touches the template itself — it only writes to the target
directory — so you can run it many times to spin up multiple vaults.

## Quick start

### macOS / Linux

```bash
git clone <your-fork-url> Daemon-Vault-Template
cd Daemon-Vault-Template
./setup/setup.sh ~/MyVault
```

### Windows (PowerShell)

```powershell
git clone <your-fork-url> Daemon-Vault-Template
cd Daemon-Vault-Template
# If scripts are blocked the first time:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
./setup/setup.ps1 "$HOME\MyVault"
```

You will be prompted for:

| Prompt | Replaces token | Example |
|--------|----------------|---------|
| Author / your name | `{{AUTHOR}}` | `Ada Lovelace` |
| Institution (optional) | `{{INSTITUTION}}` | `Example University` |
| Frontmatter tag (optional) | `{{COURSE_TAG}}` | `personal` |
| Second frontmatter tag (optional) | `{{YEAR_TAG}}` | `2026` |

Any prompt you leave blank keeps a neutral default. The last three only appear in
template frontmatter, so they are safe to ignore if you don't need them.

## Options

| bash | PowerShell | Effect |
|------|-----------|--------|
| `--download-plugins` | `-DownloadPlugins` | Fetch plugins from GitHub releases |
| `--author NAME` | `-Author NAME` | Set author non-interactively |
| `--institution NAME` | `-Institution NAME` | Set institution non-interactively |
| `--course-tag TAG` | `-CourseTag TAG` | Set course tag non-interactively |
| `--year-tag TAG` | `-YearTag TAG` | Set year tag non-interactively |
| `--force` | `-Force` | Copy into a non-empty target |
| `--yes` | `-Yes` | Accept all defaults, never prompt |

Non-interactive examples:

```bash
# macOS / Linux
./setup/setup.sh ~/MyVault --yes --author "Ada Lovelace" \
  --institution "Example University" --course-tag CS101 --year-tag year-1 --download-plugins
```

```powershell
# Windows (PowerShell)
./setup/setup.ps1 -TargetDir "$HOME\MyVault" -Yes -Author "Ada Lovelace" `
  -Institution "Example University" -CourseTag CS101 -YearTag year-1 -DownloadPlugins
```

With every identity value supplied and `-Yes` set, the script runs start to
finish without a single prompt — handy for scripted or repeated vault creation.

## Community plugins

Obsidian installs community plugins through its own interface, so by default the
script does **not** install them — it prints a checklist instead. Two ways to get them:

**A. In-app (recommended, always works).**
Settings ▸ Community plugins ▸ Browse, then install each plugin from `plugins.txt`.
The vault already lists them as enabled in `.obsidian/community-plugins.json`, so
they light up as soon as they are installed.

**B. Scripted (`--download-plugins` / `-DownloadPlugins`).**
The script reads Obsidian's official community-plugins registry to map each
plugin id to its GitHub repo, then downloads `manifest.json`, `main.js`, and
`styles.css` from the plugin's latest release. This needs network access and
`curl` + (`jq` or `python3`) on macOS/Linux; PowerShell handles it natively on
Windows. Any plugin that doesn't publish standard release assets is skipped with
a warning — install those from the app.

Two plugins are **required** for the dashboards and note banners to render:

- **Dataview** — then enable *Settings ▸ Dataview ▸ Enable JavaScript Queries*.
- **Templater** — then enable *Trigger on new file creation* and *Folder Templates*,
  and map `/` → `00Meta/Templates/Default-Note-Template.md`.

Everything else is optional quality-of-life.

## Visual walkthrough

Screenshots of the manual steps the script prints at the end. Everything below
lives in **Settings** (the gear icon, bottom-left of the app) unless noted.

### 1. Enable Dataview JavaScript queries

The note banner and the dashboard are DataviewJS views, so they stay blank
until this is switched on: **Settings ▸ Dataview ▸ Enable JavaScript queries**
(leave *Enable inline queries* on as well). The banner renders as soon as the
toggle flips — no reload needed.

![Dataview settings with "Enable JavaScript queries" switched on, and the Active Context banner rendering below](assets/enable-dataview-js.png)

### 2. Point Templater at the template folder

**Settings ▸ Templater ▸ Template folder location** → `00Meta/Templates`.
While you are on this page, scroll down and also turn on **Trigger Templater
on new file creation** and **Folder templates**, mapping `/` →
`00Meta/Templates/Default-Note-Template.md` — that is what stamps every new
note with the default template automatically.

![Templater settings with the template folder location set to 00Meta/Templates](assets/templater-folder-setup.png)

### 3. Create a note from a template

Open the command palette (**Ctrl + P** / **Cmd + P**) and run **Templater:
Create new note from template**, then pick a template — *General-Note-Template*
adapts to the note type you choose. If you use it a lot, bind it to a hotkey in
**Settings ▸ Hotkeys**.

![Command palette showing the Templater commands and the template picker with Default and General note templates](assets/templater-new-note.png)

### 4. What you should end up with

`Dashboard.md` opens on startup: the active-context banner, a *Continue
working* panel, recent notes, and vault-review stats — all rendered live by
Dataview.

![The finished vault: Dashboard open with the banner, recent notes table, and vault review stats](assets/vault-overview.png)

## Troubleshooting

- **Dashboards show code instead of tables** → Dataview JavaScript Queries is off, or
  Dataview isn't installed. Enable it and reload.
- **New notes don't get a banner / template** → Templater "Trigger on new file
  creation" and the `/` Folder Template mapping are not set.
- **Theme looks plain** → Settings ▸ Appearance ▸ Themes ▸ **NetrunnerVault**.
- **Windows: "running scripts is disabled"** → run
  `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` in the same session,
  then re-run the script.
- **"Failed to load plugin …" after install** → the download was incomplete or
  corrupted. Toggle the plugin off, delete it with the bin icon, then
  **Community plugins ▸ Browse**, search for it and reinstall — your settings
  for it are kept.

  ![Fixing a plugin that failed to load: toggle off, delete, then Browse, search, and reinstall](assets/plugin-failed-to-load.png)
- **Icons missing** → the Iconize/Icons plugins download icon packs on first use;
  open their settings and add a pack (e.g. Font Awesome / Lucide).
