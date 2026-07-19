const host = dv.container.closest(".markdown-preview-view, .markdown-source-view")
  ?? dv.container.parentElement;
const hasBanner = host?.querySelector(".nv-note-banner");

if (!hasBanner) {
  const page = dv.current() ?? {};
  const file = page.file ?? {};
  const textValue = value => {
    const candidate = dv.isArray(value) ? value[0] : value;
    return candidate === null || candidate === undefined
      ? ""
      : String(candidate).trim();
  };

  const titleValue = textValue(file.name) || textValue(page.title) || "Untitled";
  const folderValue = textValue(file.folder) || "NetrunnerVault";
  const modifiedValue = typeof file.mtime?.toFormat === "function"
    ? file.mtime.toFormat("dd LLL yyyy · HH:mm")
    : "recently modified";
  const typeValue = textValue(page.type)
    || textValue(page.note_type)
    || textValue(page.category)
    || "NOTES";
  const statusValue = textValue(page.status) || "ACTIVE";

  const panel = dv.el("section", "", {
    cls: "nv-focus-panel nv-note-banner",
    attr: { "aria-label": `${titleValue} note context` },
  });

  const eyebrow = document.createElement("div");
  eyebrow.className = "nv-focus-panel__eyebrow";
  eyebrow.textContent = "ACTIVE CONTEXT";

  const title = document.createElement("div");
  title.className = "nv-focus-panel__title";
  title.textContent = titleValue;

  const meta = document.createElement("div");
  meta.className = "nv-focus-panel__meta";
  meta.textContent = `${folderValue} · ${modifiedValue}`;

  const badges = document.createElement("div");
  badges.className = "nv-focus-panel__badges";
  for (const value of [typeValue, statusValue]) {
    const badge = document.createElement("span");
    badge.className = "htb-badge";
    badge.textContent = value;
    badges.append(badge);
  }

  panel.append(eyebrow, title, meta, badges);
}
