"""Static package inventory check; no language sources are built or run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/o/odd_even_jump_reachability_count.c",
    "c3": "c3/o/odd_even_jump_reachability_count.c3",
    "cpp": "cpp/o/odd_even_jump_reachability_count.cpp",
    "elisa": "elisa/o/odd_even_jump_reachability_count.elisa",
    "mojo": "mojo/o/odd_even_jump_reachability_count.mojo",
    "nim": "nim/o/odd_even_jump_reachability_count.nim",
    "odin": "odin/o/odd_even_jump_reachability_count.odin",
    "rust": "rust/o/odd_even_jump_reachability_count.rs",
    "v": "v/o/odd_even_jump_reachability_count.v",
    "zig": "zig/o/odd_even_jump_reachability_count.zig",
}


def static_issues() -> list[str]:
    metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if metadata.get("algorithm") != "odd_even_jump_reachability_count":
        issues.append("inventory algorithm name differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        issues.append("inventory language map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            issues.append(f"missing port: {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    return issues
