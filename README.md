# Daemon Vault Template

A clean, general-purpose **Obsidian** starter vault — packaged so anyone can
spin up their own copy in one command.

It ships a custom **Rosé Pine Editorial** theme, a self-updating note banner,
flexible note templates, a live dashboard, and cross-platform setup scripts that
personalise everything for you. No opinionated folders, no niche content — just
a well-styled, working foundation you organise your own way.

> **New here?** Run the setup script (below) — don't copy the `vault/` folder by
> hand. The script fills in your details and prints the final steps.

---

## Highlights

- **Custom theme** — *NetrunnerVault*, a standalone Rosé Pine Editorial theme
  (Dawn light / Moon dark). Quiet reading surfaces, clear hierarchy, and a dark
  terminal frame for code blocks.
- **Self-updating note banner** — an "active context" card at the top of every
  note that reflects its folder, type, status, and last-modified time, and
  updates automatically when you move or rename the note.
- **Note templates** (Templater) — a flexible **General note** template that
  adapts to the note type you pick (Quick Note, Research, Meeting, Idea,
  Tutorial, Reference), plus a **Default** template every new note picks up
  automatically.
- **Live dashboard** — recent notes, a "continue working" focus panel, and simple
  upkeep stats, all built with Dataview.
- **Vault-maintenance scripts** — optional Python helpers: a read-only
  `vault_health.py`, a dry-run `vault_organizer.py`, and a `hasher.py` for file
  integrity.
- **One-command setup** for macOS, Linux, and Windows.

---

## Quick start

```bash
# macOS / Linux
git clone <your-fork-url> Daemon-Vault-Template
cd Daemon-Vault-Template
./setup/setup.sh ~/MyVault
```

```powershell
# Windows (PowerShell)
git clone <your-fork-url> Daemon-Vault-Template
cd Daemon-Vault-Template
./setup/setup.ps1 "$HOME\MyVault"
```

The script copies the template to your target folder, asks for a few identity
values, and prints the last manual steps. Add `--download-plugins`
(`-DownloadPlugins` on Windows) to fetch the community plugins automatically.

Full options, the plugin list, and troubleshooting live in
**[setup/SETUP.md](setup/SETUP.md)**.

After the script finishes: open the target folder as a vault in Obsidian, turn
off Restricted mode, install the plugins, enable **Dataview → JavaScript
Queries** and the **Templater** folder template, and pick the **NetrunnerVault**
theme. `Dashboard.md` opens on startup — start from [[Welcome]].

---

## What's inside

```
Daemon-Vault-Template/
├── README.md
├── LICENSE                      # MIT
├── setup/
│   ├── setup.sh                 # macOS / Linux initialiser
│   ├── setup.ps1                # Windows initialiser
│   ├── plugins.txt              # community-plugin list (source of truth)
│   └── SETUP.md                 # setup + plugin + settings guide
└── vault/                       # the template vault the script copies
    ├── .obsidian/               # config, theme, snippets, plugin manifests
    ├── 00Meta/
    │   ├── Templates/           # Default + General note templates
    │   ├── Views/NoteBanner/    # Dataview view powering the note banner
    │   └── Scripts/             # vault_health / vault_organizer / hasher
    ├── Notes/                   # a starter folder with one example note
    ├── Welcome.md               # start-here guide
    ├── Dashboard.md             # home dashboard
    └── Vault.md
```

`Welcome.md` and `Notes/Example Note.md` exist so the dashboard and theme render
something on first open. Delete them once you get going, and create whatever
top-level folders fit how *you* think.

---

## Personalisation

The setup script replaces four placeholder tokens so the notes read as yours:

| Token | Meaning |
|-------|---------|
| `{{AUTHOR}}` | Your name / handle |
| `{{INSTITUTION}}` | Your school or organisation (optional) |
| `{{COURSE_TAG}}` | A tag used in note frontmatter (optional) |
| `{{YEAR_TAG}}` | A second frontmatter tag (optional) |

Re-run the script into a new folder any time to create another vault with
different values. To change them later, do a find-and-replace in your vault.

---

## Requirements

- [Obsidian](https://obsidian.md) 1.4 or newer.
- Community plugins (installed in-app or via `--download-plugins`) — see
  [setup/SETUP.md](setup/SETUP.md). **Dataview** and **Templater** are required;
  the rest are optional quality-of-life.
- Python 3 (only for the optional maintenance scripts in `00Meta/Scripts`).

---

## Credits & licence

- Theme palette: **[Rosé Pine](https://rosepinetheme.com)**.
- Template code, theme CSS, and scripts are released under the **MIT License**
  (see [LICENSE](LICENSE)). Bundled community plugins remain under their own
  licences and are fetched from their upstream releases, not redistributed here.
