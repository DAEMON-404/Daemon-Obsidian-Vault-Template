#!/usr/bin/env python3
"""Read-only health checks for an Obsidian vault."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence


EXCLUDED_DIRECTORIES = {".git", ".makemd", ".space", ".trash", "node_modules"}
# Notes anywhere except the meta folder count as "content" for frontmatter checks.
META_ROOT = "00Meta"
FENCED_BLOCK = re.compile(r"```.*?```|~~~.*?~~~", re.DOTALL)
EMBED = re.compile(r"!\[\[([^\]]+)\]\]")


@dataclass(frozen=True)
class Finding:
    code: str
    path: str
    message: str
    severity: str = "warning"


@dataclass
class AuditReport:
    root: str
    note_count: int
    findings: list[Finding]

    @property
    def has_actionable_findings(self) -> bool:
        return any(finding.severity in {"error", "warning"} for finding in self.findings)

    def to_dict(self) -> dict[str, Any]:
        return {
            "root": self.root,
            "note_count": self.note_count,
            "has_actionable_findings": self.has_actionable_findings,
            "counts": dict(sorted(Counter(finding.code for finding in self.findings).items())),
            "findings": [asdict(finding) for finding in self.findings],
        }


def _is_excluded(path: Path) -> bool:
    return any(part in EXCLUDED_DIRECTORIES for part in path.parts)


def _content_files(root: Path) -> list[Path]:
    return sorted(
        (
            path
            for path in root.rglob("*")
            if path.is_file() and not _is_excluded(path.relative_to(root)) and ".obsidian" not in path.parts
        ),
        key=lambda path: path.as_posix().casefold(),
    )


def _frontmatter(text: str) -> dict[str, str] | None:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    try:
        end = next(index for index, line in enumerate(lines[1:], start=1) if line.strip() == "---")
    except StopIteration:
        return None
    properties: dict[str, str] = {}
    for line in lines[1:end]:
        match = re.match(r"^([A-Za-z_][\w-]*):\s*(.*?)\s*$", line)
        if match:
            properties[match.group(1)] = match.group(2).strip("\"'")
    return properties


def _is_sensitive_key(key: str) -> bool:
    normalized = re.sub(r"[^a-z0-9]", "", key.casefold())
    return normalized in {"credential", "password", "passphrase", "secret", "token"} or normalized.endswith(
        ("accesstoken", "apikey", "clientsecret", "credential", "password", "privatekey", "refreshtoken")
    )


def _is_populated_scalar(value: Any) -> bool:
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, bool) or value is None:
        return False
    return isinstance(value, (int, float)) and value != 0


def _sensitive_paths(value: Any, prefix: tuple[str, ...] = ()) -> Iterable[tuple[str, ...]]:
    if isinstance(value, dict):
        for key, child in value.items():
            path = (*prefix, str(key))
            if _is_sensitive_key(str(key)) and _is_populated_scalar(child):
                yield path
            yield from _sensitive_paths(child, path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from _sensitive_paths(child, (*prefix, str(index)))


def audit_vault(root: Path, large_file_bytes: int = 25 * 1024 * 1024) -> AuditReport:
    root = root.absolute()
    files = _content_files(root)
    notes = [path for path in files if path.suffix.casefold() == ".md"]
    findings: list[Finding] = []
    file_names = defaultdict(list)
    for path in files:
        file_names[path.name.casefold()].append(path)
        file_names[path.stem.casefold()].append(path)

    for note in notes:
        relative = note.relative_to(root)
        text = note.read_text(encoding="utf-8", errors="replace")
        if not text.strip():
            findings.append(Finding("empty_note", relative.as_posix(), "Note is empty."))
            continue

        properties = _frontmatter(text)
        if relative.parts and relative.parts[0] != META_ROOT and properties is None:
            findings.append(
                Finding("missing_frontmatter", relative.as_posix(), "Content note has no YAML frontmatter.")
            )

        if "00_Meta" in text:
            findings.append(
                Finding("legacy_meta_reference", relative.as_posix(), "Contains the obsolete 00_Meta path.")
            )

        searchable = FENCED_BLOCK.sub("", text)
        for raw_target in EMBED.findall(searchable):
            target = raw_target.split("|", 1)[0].split("#", 1)[0].strip()
            if not target:
                continue
            local = note.parent / target
            vault_relative = root / target
            if local.exists() or vault_relative.exists():
                continue
            key = Path(target).name.casefold()
            stem = Path(target).stem.casefold()
            if key in file_names or stem in file_names:
                continue
            findings.append(
                Finding("unresolved_embed", relative.as_posix(), f"Embedded file was not found: {target}.")
            )

    for data_file in sorted(root.glob(".obsidian/plugins/*/data.json")):
        try:
            data = json.loads(data_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        sensitive = sorted(".".join(path) for path in _sensitive_paths(data))
        if sensitive:
            relative = data_file.relative_to(root).as_posix()
            findings.append(
                Finding(
                    "sensitive_plugin_data",
                    relative,
                    "Plugin data contains populated sensitive fields: " + ", ".join(sensitive) + ".",
                    severity="error",
                )
            )

    for path in files:
        try:
            size = path.stat().st_size
        except OSError:
            continue
        if size > large_file_bytes:
            relative = path.relative_to(root).as_posix()
            findings.append(
                Finding("large_file", relative, f"File is {size / 1024 / 1024:.1f} MiB.", severity="info")
            )

    findings.sort(key=lambda finding: (finding.code, finding.path, finding.message))
    return AuditReport(root=str(root), note_count=len(notes), findings=findings)


def _format_report(report: AuditReport) -> str:
    counts = Counter(finding.code for finding in report.findings)
    lines = [f"Vault health: {report.note_count} notes, {len(report.findings)} findings"]
    if counts:
        lines.append("Summary:")
        for code, count in sorted(counts.items()):
            lines.append(f"  {code}: {count}")
        lines.append("Findings:")
        for finding in report.findings:
            lines.append(f"  [{finding.severity.upper()}] {finding.code} {finding.path} — {finding.message}")
    else:
        lines.append("No findings.")
    return "\n".join(lines)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run read-only Obsidian vault health checks.")
    parser.add_argument("--root", type=Path, default=Path("."), help="Vault root (default: current directory)")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero when warnings or errors exist")
    parser.add_argument("--json", action="store_true", dest="as_json", help="Emit JSON")
    parser.add_argument("--large-file-mib", type=int, default=25, help="Large-file threshold in MiB")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    report = audit_vault(args.root, large_file_bytes=args.large_file_mib * 1024 * 1024)
    if args.as_json:
        print(json.dumps(report.to_dict(), indent=2))
    else:
        print(_format_report(report))
    return 1 if args.strict and report.has_actionable_findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
