<#
.SYNOPSIS
    Daemon-Vault-Template - vault initialiser (Windows / PowerShell).

.DESCRIPTION
    Copies the template vault to a new location, personalises the placeholder
    tokens, and optionally downloads the required community plugins.

.PARAMETER TargetDir
    Directory to create the new vault in.

.PARAMETER DownloadPlugins
    Fetch community plugins from their GitHub releases.

.PARAMETER Author, Institution, CourseTag, YearTag
    Set identity values without prompting.

.PARAMETER Force
    Allow copying into a non-empty target directory.

.PARAMETER Yes
    Accept all defaults, never prompt.

.EXAMPLE
    ./setup/setup.ps1 -TargetDir "$HOME\MyVault"

.EXAMPLE
    ./setup/setup.ps1 "$HOME\MyVault" -DownloadPlugins
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string] $TargetDir,
    [switch] $DownloadPlugins,
    [string] $Author,
    [string] $Institution,
    [string] $CourseTag,
    [string] $YearTag,
    [switch] $Force,
    [switch] $Yes
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Locate repo root and source vault (this script lives in <repo>/setup).
# ---------------------------------------------------------------------------
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot    = Split-Path -Parent $ScriptDir
$VaultSrc    = Join-Path $RepoRoot 'vault'
$PluginsFile = Join-Path $ScriptDir 'plugins.txt'
$RegistryUrl = 'https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json'

$DefAuthor = 'Analyst'; $DefInstitution = 'Your Institution'
$DefCourseTag = 'SECURITY'; $DefYearTag = 'year-1'

function Info($m) { Write-Host "==> $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Err ($m) { Write-Host "[x] $m" -ForegroundColor Red }
function Step($m) { Write-Host "`n$m" -ForegroundColor Cyan }

function Ask($question, $default) {
    if ($Yes) { return $default }
    $ans = Read-Host "$question [$default]"
    if ([string]::IsNullOrWhiteSpace($ans)) { return $default } else { return $ans }
}

if (-not (Test-Path $VaultSrc)) { Err "Cannot find template vault at $VaultSrc"; exit 1 }

Step 'Daemon-Vault-Template setup'

# Target directory
if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    $TargetDir = Ask 'Where should the new vault be created?' (Join-Path $HOME 'MyVault')
}
$TargetDir = [System.Environment]::ExpandEnvironmentVariables($TargetDir)

if ((Test-Path $TargetDir) -and (Get-ChildItem -Force $TargetDir | Select-Object -First 1) -and (-not $Force)) {
    Err "Target '$TargetDir' exists and is not empty. Re-run with -Force to copy into it anyway."
    exit 1
}

# Identity values
if (-not $Author)      { $Author      = Ask 'Author / operator name' $DefAuthor }
if (-not $Institution) { $Institution = Ask 'Institution (school / org)' $DefInstitution }
if (-not $CourseTag)   { $CourseTag   = Ask 'Course / module tag (no spaces)' $DefCourseTag }
if (-not $YearTag)     { $YearTag     = Ask 'Academic-year tag (no spaces)' $DefYearTag }

# ---------------------------------------------------------------------------
# Copy the vault
# ---------------------------------------------------------------------------
Step "Copying template vault -> $TargetDir"
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
Copy-Item -Path (Join-Path $VaultSrc '*') -Destination $TargetDir -Recurse -Force
Get-ChildItem -Path $TargetDir -Recurse -Force -Filter '.DS_Store' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
# Never propagate Python bytecode caches into a new vault.
Get-ChildItem -Path $TargetDir -Recurse -Force -Directory -Filter '__pycache__' -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $TargetDir -Recurse -Force -Filter '*.pyc' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
Info 'Vault copied.'

# ---------------------------------------------------------------------------
# Substitute placeholders
# ---------------------------------------------------------------------------
Step 'Personalising placeholders'
Write-Host ("  author:      {0}" -f $Author)
Write-Host ("  institution: {0}" -f $Institution)
Write-Host ("  course tag:  {0}" -f $CourseTag)
Write-Host ("  year tag:    {0}" -f $YearTag)

$map = @{
    '{{AUTHOR}}'      = $Author
    '{{INSTITUTION}}' = $Institution
    '{{COURSE_TAG}}'  = $CourseTag
    '{{YEAR_TAG}}'    = $YearTag
}
$exts = @('*.md', '*.js', '*.py', '*.json', '*.css')
$files = Get-ChildItem -Path $TargetDir -Recurse -File -Include $exts
$count = 0
foreach ($file in $files) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $orig = $text
    foreach ($k in $map.Keys) { $text = $text.Replace($k, $map[$k]) }
    if ($text -ne $orig) {
        # Write UTF-8 without BOM to keep Obsidian happy.
        [System.IO.File]::WriteAllText($file.FullName, $text, (New-Object System.Text.UTF8Encoding($false)))
    }
    $count++
}
Info "Personalised $count files."

# ---------------------------------------------------------------------------
# Optional: download community plugins
# ---------------------------------------------------------------------------
function Get-PluginIds {
    Get-Content $PluginsFile |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } |
        ForEach-Object { ($_ -split '\s+')[0] }
}

function Download-Plugins {
    Step 'Downloading community plugins'
    try {
        Info 'Fetching plugin registry...'
        $registry = Invoke-RestMethod -Uri $RegistryUrl -ErrorAction Stop
    } catch {
        Err "Could not fetch registry - skipping. ($($_.Exception.Message))"
        return
    }
    $index = @{}
    foreach ($p in $registry) { $index[$p.id] = $p.repo }

    $ok = 0; $fail = 0
    foreach ($id in Get-PluginIds) {
        if (-not $index.ContainsKey($id)) { Warn "$id - not found in registry, skipping."; $fail++; continue }
        $repo = $index[$id]
        $dir  = Join-Path $TargetDir ".obsidian\plugins\$id"
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $base = "https://github.com/$repo/releases/latest/download"
        try {
            Invoke-WebRequest -Uri "$base/manifest.json" -OutFile (Join-Path $dir 'manifest.json') -ErrorAction Stop
            Invoke-WebRequest -Uri "$base/main.js"       -OutFile (Join-Path $dir 'main.js')       -ErrorAction Stop
            try { Invoke-WebRequest -Uri "$base/styles.css" -OutFile (Join-Path $dir 'styles.css') -ErrorAction Stop } catch { }
            Info "$id  <-  $repo"; $ok++
        } catch {
            Warn "$id - release download failed ($repo). Install it in-app instead."
            $fail++
        }
    }
    Info "Plugins downloaded: $ok, failed/skipped: $fail"
}

if ($DownloadPlugins) { Download-Plugins }

# ---------------------------------------------------------------------------
# Final instructions
# ---------------------------------------------------------------------------
Step 'Almost done - final manual steps in Obsidian'
Write-Host "  1. Open Obsidian > 'Open folder as vault' > select:"
Write-Host "       $TargetDir"
Write-Host "  2. Settings > Community plugins > turn OFF Restricted mode."

if (-not $DownloadPlugins) {
    Write-Host "  3. Install these community plugins (Settings > Community plugins > Browse):"
    Get-Content $PluginsFile |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } |
        ForEach-Object {
            if ($_ -match '#\s*(.+)$') { "       - $($matches[1].Trim())" }
            else { "       - $((($_ -split '\s+')[0]))" }
        }
} else {
    Write-Host "  3. Community plugins were downloaded into .obsidian\plugins (already listed as enabled)."
}

Write-Host @"
  4. Enable the two required settings:
       - Settings > Dataview > Enable JavaScript Queries   (dashboards + note banners)
       - Settings > Templater > Trigger on new file creation = ON,
         Folder Templates = ON, map "/" -> 00Meta/Templates/Default-Note-Template.md
  5. Settings > Appearance > Themes > NetrunnerVault  (already selected; reload if needed).
  6. Reload Obsidian. Dashboard.md opens on startup.

  Done.  See setup/SETUP.md for details and troubleshooting.
"@
