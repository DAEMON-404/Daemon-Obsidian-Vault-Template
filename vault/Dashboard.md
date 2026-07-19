---
title: "Vault"
type: dashboard
status: active
creation_date: 2026-07-13
cssclasses:
  - dashboard
  - editorial
  - note-banner
tags:
  - meta/dashboard
---

```dataviewjs
await dv.view("00Meta/Views/NoteBanner");
```

<div class="nv-workspace-bar">
  <span class="nv-workspace-bar__brand">Vault</span>
  <span class="nv-workspace-bar__context">home · <kbd>⌘ K</kbd> search</span>
</div>

<div class="nv-circuit-trace" aria-hidden="true"></div>

> [!dashboard] Start here
> Resume the note you were last working on, create a new one from a template, or review what needs attention. New to the vault? Open [[Welcome]].

## Continue working

```dataviewjs
const candidates = dv.pages()
  .where(p => p.file?.ext === "md")
  .where(p => !/^00Meta(\/|$)/.test(p.file.folder))
  .where(p => !/dashboard|template|-moc/i.test(p.file.name))
  .where(p => !/(^|\/)attachments?(\/|$)/i.test(p.file.folder))
  .sort(p => p.file.mtime, "desc")
  .array();

const recent = candidates[0];
if (!recent) {
  dv.el("div", "Create or edit a note to populate this panel.", { cls: "nv-empty-state" });
} else {
  const panel = dv.el("section", "", { cls: "nv-focus-panel" });

  const eyebrow = document.createElement("div");
  eyebrow.className = "nv-focus-panel__eyebrow";
  eyebrow.textContent = "Active context";

  const title = document.createElement("div");
  title.className = "nv-focus-panel__title";
  const link = document.createElement("a");
  link.className = "internal-link";
  link.setAttribute("data-href", recent.file.path);
  link.setAttribute("href", recent.file.path);
  link.textContent = recent.file.name;
  title.append(link);

  const meta = document.createElement("div");
  meta.className = "nv-focus-panel__meta";
  const modified = typeof recent.file.mtime?.toFormat === "function"
    ? recent.file.mtime.toFormat("dd LLL yyyy · HH:mm")
    : "recently modified";
  meta.textContent = `${recent.file.folder || "Vault"} · ${modified}`;

  panel.append(eyebrow, title, meta);

  const badgeValues = [recent.type, recent.status]
    .filter(value => value !== null && value !== undefined && String(value).trim())
    .map(value => String(value).trim())
    .slice(0, 2);
  if (badgeValues.length) {
    const badges = document.createElement("div");
    badges.className = "nv-focus-panel__badges";
    for (const value of badgeValues) {
      const badge = document.createElement("span");
      badge.className = "htb-badge";
      badge.textContent = value;
      badges.append(badge);
    }
    panel.append(badges);
  }
}
```

### Recently modified

```dataview
TABLE WITHOUT ID
  file.link AS "Note",
  file.folder AS "Location",
  dateformat(file.mtime, "yyyy-MM-dd HH:mm") AS "Modified"
FROM !"00Meta"
WHERE !contains(lower(file.name), "dashboard")
  AND !contains(lower(file.name), "template")
SORT file.mtime DESC
LIMIT 10
```

## Vault review

```dataviewjs
const reviewPages = dv.pages()
  .where(p => p.file?.ext === "md")
  .where(p => !/^00Meta(\/|$)/.test(p.file.folder))
  .array();
const unclassified = reviewPages.filter(p => !p.type).length;
const untagged = reviewPages.filter(p => !p.file.tags || p.file.tags.length === 0).length;
const emptyNotes = reviewPages.filter(p =>
  p.file.size !== null && p.file.size !== undefined && Number(p.file.size) === 0
).length;

const grid = dv.el("div", "", { cls: "nv-review-grid" });
for (const [value, label] of [
  [unclassified, "Notes without a type"],
  [untagged, "Untagged notes"],
  [emptyNotes, "Empty notes"],
]) {
  const stat = document.createElement("div");
  stat.className = "nv-review-stat";
  const number = document.createElement("strong");
  number.textContent = String(value);
  const caption = document.createElement("span");
  caption.textContent = label;
  stat.append(number, caption);
  grid.append(stat);
}
```

> [!info]- Full maintenance audit
> Run `python3 00Meta/Scripts/vault_health.py` for unresolved embeds and filesystem checks that Dataview cannot verify.

## Create a note

> [!grid]
> - **General note** — `General-Note-Template` (prompts for a type: Quick Note, Research, Meeting, Idea, Tutorial, Reference)
> - **Blank note** — every new note picks up `Default-Note-Template` automatically via Templater's folder template.

Press `Ctrl/Cmd + P` and run **Templater: Open Insert Template modal**.

## Recently tagged

```dataview
TABLE WITHOUT ID
  file.link AS "Note",
  file.tags AS "Tags"
FROM !"00Meta"
WHERE file.tags AND !contains(lower(file.name), "dashboard")
SORT file.mtime DESC
LIMIT 10
```
