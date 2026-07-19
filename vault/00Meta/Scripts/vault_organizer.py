#!/usr/bin/env python3
"""Safely move loose vault-root files into the canonical meta folders.

The command is a dry run unless ``--apply`` is supplied. It deliberately does
not recurse, rename notes, update links, or delete files.
"""

from __future__ import annotations

import argparse
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


IMAGE_EXTENSIONS = {".gif", ".jpeg", ".jpg", ".png", ".svg", ".webp"}
DOCUMENT_EXTENSIONS = {".md", ".pdf", ".txt"}
PRESERVED_ROOT_FILES = {
    "AGENTS.md",
    "CLAUDE.md",
    "Dashboard.md",
    "LICENSE",
    "README.md",
    "Vault.md",
    "Welcome.md",
}


class CollisionError(RuntimeError):
    """Raised when applying a move would overwrite an existing file."""


@dataclass(frozen=True)
class Move:
    source: Path
    destination: Path


def build_plan(vault_root: Path) -> list[Move]:
    """Return moves for supported loose files directly beneath ``vault_root``."""

    vault_root = vault_root.absolute()
    assets = vault_root / "00Meta" / "Assets"
    inbox = vault_root / "00Meta" / "Inbox"
    moves: list[Move] = []

    for item in sorted(vault_root.iterdir(), key=lambda path: path.name.casefold()):
        if not item.is_file() or item.name.startswith(".") or item.name in PRESERVED_ROOT_FILES:
            continue
        suffix = item.suffix.lower()
        if suffix in IMAGE_EXTENSIONS:
            moves.append(Move(source=item, destination=assets / item.name))
        elif suffix in DOCUMENT_EXTENSIONS:
            moves.append(Move(source=item, destination=inbox / item.name))

    return moves


def _validate_plan(plan: Iterable[Move]) -> list[Move]:
    moves = list(plan)
    destinations: set[Path] = set()
    for move in moves:
        if not move.source.is_file():
            raise FileNotFoundError(f"Source file does not exist: {move.source}")
        if move.destination.exists() or move.destination in destinations:
            raise CollisionError(f"Refusing to overwrite: {move.destination}")
        destinations.add(move.destination)
    return moves


def apply_plan(plan: Iterable[Move]) -> None:
    """Validate the complete plan, then apply it without overwriting files."""

    moves = _validate_plan(plan)
    for move in moves:
        move.destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(move.source), str(move.destination))


def format_plan(plan: Sequence[Move], vault_root: Path) -> str:
    if not plan:
        return "No loose root files need organising."
    lines = ["Planned moves:"]
    for move in plan:
        source = move.source.relative_to(vault_root)
        destination = move.destination.relative_to(vault_root)
        lines.append(f"  {source} -> {destination}")
    return "\n".join(lines)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Move supported loose root files into 00Meta (dry-run by default)."
    )
    parser.add_argument("--root", type=Path, default=Path("."), help="Vault root (default: current directory)")
    parser.add_argument("--apply", action="store_true", help="Apply the displayed move plan")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    root = args.root.resolve()
    plan = build_plan(root)
    print(format_plan(plan, root))
    if args.apply and plan:
        apply_plan(plan)
        print(f"Applied {len(plan)} move(s).")
    elif plan:
        print("Dry run only. Re-run with --apply to move these files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
