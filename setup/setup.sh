#!/usr/bin/env bash
#
# Daemon-Vault-Template — vault initialiser (macOS / Linux)
#
# Copies the template vault to a new location, personalises the placeholder
# tokens, and (optionally) downloads the required community plugins.
#
# Usage:
#   ./setup/setup.sh [TARGET_DIR] [options]
#
# Options:
#   --download-plugins   Fetch community plugins from their GitHub releases.
#   --author NAME        Set author without prompting.
#   --institution NAME   Set institution without prompting.
#   --course-tag TAG     Set course/module tag without prompting.
#   --year-tag TAG       Set academic-year tag without prompting.
#   --force              Allow copying into a non-empty target directory.
#   --yes                Accept all defaults, never prompt (implies non-interactive).
#   -h, --help           Show this help.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Locate repo root and the source vault (this script lives in <repo>/setup).
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_SRC="$REPO_ROOT/vault"
PLUGINS_FILE="$SCRIPT_DIR/plugins.txt"
REGISTRY_URL="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json"

# ---------------------------------------------------------------------------
# Defaults / arg parsing
# ---------------------------------------------------------------------------
TARGET_DIR=""
DOWNLOAD_PLUGINS=0
FORCE=0
ASSUME_YES=0
AUTHOR=""
INSTITUTION=""
COURSE_TAG=""
YEAR_TAG=""

DEF_AUTHOR="Analyst"
DEF_INSTITUTION="Your Institution"
DEF_COURSE_TAG="SECURITY"
DEF_YEAR_TAG="year-1"

c_bold=$'\033[1m'; c_dim=$'\033[2m'; c_grn=$'\033[32m'; c_ylw=$'\033[33m'; c_red=$'\033[31m'; c_rst=$'\033[0m'
info()  { printf '%s\n' "${c_grn}==>${c_rst} $*"; }
warn()  { printf '%s\n' "${c_ylw}[!]${c_rst} $*" >&2; }
err()   { printf '%s\n' "${c_red}[x]${c_rst} $*" >&2; }
step()  { printf '\n%s\n' "${c_bold}$*${c_rst}"; }

usage() { sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --download-plugins) DOWNLOAD_PLUGINS=1 ;;
    --force)            FORCE=1 ;;
    --yes|-y)           ASSUME_YES=1 ;;
    --author)           AUTHOR="${2:-}"; shift ;;
    --institution)      INSTITUTION="${2:-}"; shift ;;
    --course-tag)       COURSE_TAG="${2:-}"; shift ;;
    --year-tag)         YEAR_TAG="${2:-}"; shift ;;
    -h|--help)          usage ;;
    -*)                 err "Unknown option: $1"; exit 2 ;;
    *)                  if [ -z "$TARGET_DIR" ]; then TARGET_DIR="$1"; else err "Unexpected argument: $1"; exit 2; fi ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
[ -d "$VAULT_SRC" ] || { err "Cannot find template vault at $VAULT_SRC"; exit 1; }

prompt() { # prompt <var-name> <question> <default>
  local __var="$1" __q="$2" __def="$3" __ans=""
  if [ "$ASSUME_YES" -eq 1 ]; then printf -v "$__var" '%s' "$__def"; return; fi
  read -r -p "$__q [${__def}]: " __ans || true
  printf -v "$__var" '%s' "${__ans:-$__def}"
}

step "Daemon-Vault-Template setup"

# Target directory
if [ -z "$TARGET_DIR" ]; then
  prompt TARGET_DIR "Where should the new vault be created?" "$HOME/MyVault"
fi
# Expand a leading ~
case "$TARGET_DIR" in "~"/*) TARGET_DIR="$HOME/${TARGET_DIR#~/}" ;; esac

if [ -e "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR" 2>/dev/null || true)" ] && [ "$FORCE" -ne 1 ]; then
  err "Target '$TARGET_DIR' exists and is not empty. Re-run with --force to copy into it anyway."
  exit 1
fi

# Identity values
[ -n "$AUTHOR" ]      || prompt AUTHOR      "Author / operator name" "$DEF_AUTHOR"
[ -n "$INSTITUTION" ] || prompt INSTITUTION "Institution (school / org)" "$DEF_INSTITUTION"
[ -n "$COURSE_TAG" ]  || prompt COURSE_TAG  "Course / module tag (no spaces)" "$DEF_COURSE_TAG"
[ -n "$YEAR_TAG" ]    || prompt YEAR_TAG    "Academic-year tag (no spaces)" "$DEF_YEAR_TAG"

# ---------------------------------------------------------------------------
# Copy the vault
# ---------------------------------------------------------------------------
step "Copying template vault -> $TARGET_DIR"
mkdir -p "$TARGET_DIR"
# Copy contents of vault/ (including dotfiles) into TARGET_DIR.
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude '.DS_Store' --exclude '__pycache__' --exclude '*.pyc' "$VAULT_SRC"/ "$TARGET_DIR"/
else
  cp -R "$VAULT_SRC"/. "$TARGET_DIR"/
  find "$TARGET_DIR" \( -name '.DS_Store' -o -name '*.pyc' \) -delete 2>/dev/null || true
  find "$TARGET_DIR" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
fi
info "Vault copied."

# ---------------------------------------------------------------------------
# Substitute placeholders
# ---------------------------------------------------------------------------
step "Personalising placeholders"
printf '  %-14s %s\n' "author:" "$AUTHOR" "institution:" "$INSTITUTION" "course tag:" "$COURSE_TAG" "year tag:" "$YEAR_TAG"

subst_engine=""
if command -v perl >/dev/null 2>&1; then subst_engine="perl"; else subst_engine="sed"; fi

# Escape for sed replacement (only used in the sed fallback).
sed_escape() { printf '%s' "$1" | sed -e 's/[&/\]/\\&/g'; }

apply_subst() { # apply_subst <file>
  local f="$1"
  if [ "$subst_engine" = "perl" ]; then
    AUTHOR="$AUTHOR" INSTITUTION="$INSTITUTION" COURSE_TAG="$COURSE_TAG" YEAR_TAG="$YEAR_TAG" \
    perl -pi -e '
      s/\{\{AUTHOR\}\}/$ENV{AUTHOR}/g;
      s/\{\{INSTITUTION\}\}/$ENV{INSTITUTION}/g;
      s/\{\{COURSE_TAG\}\}/$ENV{COURSE_TAG}/g;
      s/\{\{YEAR_TAG\}\}/$ENV{YEAR_TAG}/g;
    ' "$f"
  else
    local a i c y
    a="$(sed_escape "$AUTHOR")"; i="$(sed_escape "$INSTITUTION")"
    c="$(sed_escape "$COURSE_TAG")"; y="$(sed_escape "$YEAR_TAG")"
    sed -i.bak \
      -e "s/{{AUTHOR}}/$a/g" \
      -e "s/{{INSTITUTION}}/$i/g" \
      -e "s/{{COURSE_TAG}}/$c/g" \
      -e "s/{{YEAR_TAG}}/$y/g" "$f"
    rm -f "$f.bak"
  fi
}

count=0
while IFS= read -r -d '' f; do
  apply_subst "$f"; count=$((count+1))
done < <(find "$TARGET_DIR" -type f \( -name '*.md' -o -name '*.js' -o -name '*.py' -o -name '*.json' -o -name '*.css' \) -print0)
info "Personalised $count files (engine: $subst_engine)."

# ---------------------------------------------------------------------------
# Optional: download community plugins
# ---------------------------------------------------------------------------
read_plugin_ids() { grep -vE '^\s*(#|$)' "$PLUGINS_FILE" | awk '{print $1}'; }

resolve_repo() { # resolve_repo <registry-json-file> <plugin-id>  -> prints owner/repo
  local reg="$1" id="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg id "$id" '.[] | select(.id==$id) | .repo' "$reg"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$reg" "$id" <<'PY'
import json,sys
reg,pid=sys.argv[1],sys.argv[2]
data=json.load(open(reg))
print(next((p.get("repo","") for p in data if p.get("id")==pid),""))
PY
  else
    echo ""
  fi
}

download_plugins() {
  step "Downloading community plugins"
  if ! command -v curl >/dev/null 2>&1; then err "curl not found — cannot download plugins."; return 1; fi
  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    err "Need jq or python3 to read the plugin registry — skipping download."
    return 1
  fi
  local reg; reg="$(mktemp)"
  info "Fetching plugin registry..."
  if ! curl -fsSL "$REGISTRY_URL" -o "$reg"; then err "Could not fetch registry — skipping."; rm -f "$reg"; return 1; fi

  local ok=0 fail=0 id repo dir
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    repo="$(resolve_repo "$reg" "$id")"
    if [ -z "$repo" ]; then warn "$id — not found in registry, skipping."; fail=$((fail+1)); continue; fi
    dir="$TARGET_DIR/.obsidian/plugins/$id"
    mkdir -p "$dir"
    local base="https://github.com/$repo/releases/latest/download"
    if curl -fsSL "$base/manifest.json" -o "$dir/manifest.json" \
       && curl -fsSL "$base/main.js" -o "$dir/main.js"; then
      curl -fsSL "$base/styles.css" -o "$dir/styles.css" 2>/dev/null || true  # optional
      info "$id  <-  $repo"; ok=$((ok+1))
    else
      warn "$id — release download failed ($repo). Install it in-app instead."
      fail=$((fail+1))
    fi
  done < <(read_plugin_ids)

  rm -f "$reg"
  info "Plugins downloaded: $ok, failed/skipped: $fail"
}

if [ "$DOWNLOAD_PLUGINS" -eq 1 ]; then
  download_plugins || warn "Plugin download incomplete — see messages above."
fi

# ---------------------------------------------------------------------------
# Final instructions
# ---------------------------------------------------------------------------
step "Almost done — final manual steps in Obsidian"
cat <<EOF
  1. Open Obsidian ▸ "Open folder as vault" ▸ select:
       $TARGET_DIR
  2. Settings ▸ Community plugins ▸ turn OFF Restricted mode.
EOF

if [ "$DOWNLOAD_PLUGINS" -ne 1 ]; then
  cat <<EOF
  3. Install these community plugins (Settings ▸ Community plugins ▸ Browse):
EOF
  # Print the friendly checklist straight from plugins.txt (portable awk).
  awk -F'#' '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      name = (NF > 1) ? $2 : $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
      print "       - " name
    }' "$PLUGINS_FILE"
else
  echo "  3. Community plugins were downloaded into .obsidian/plugins (already listed as enabled)."
fi

cat <<EOF
  4. Enable the two required settings:
       - Settings ▸ Dataview ▸ Enable JavaScript Queries   (dashboards + note banners)
       - Settings ▸ Templater ▸ Trigger on new file creation = ON,
         Folder Templates = ON, map "/" -> 00Meta/Templates/Default-Note-Template.md
  5. Settings ▸ Appearance ▸ Themes ▸ NetrunnerVault  (already selected; reload if needed).
  6. Reload Obsidian. Dashboard.md opens on startup.

  ${c_bold}Done.${c_rst}  See setup/SETUP.md for details and troubleshooting.
EOF
