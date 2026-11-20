"""Static package-path and metadata inventory check; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/v/vlist_persistent_sequence.c",
    "c3": "c3/v/vlist_persistent_sequence.c3",
    "cpp": "cpp/v/vlist_persistent_sequence.cpp",
    "elisa": "elisa/v/vlist_persistent_sequence.elisa",
    "mojo": "mojo/v/vlist_persistent_sequence.mojo",
    "nim": "nim/v/vlist_persistent_sequence.nim",
    "odin": "odin/v/vlist_persistent_sequence.odin",
    "rust": "rust/v/vlist_persistent_sequence.rs",
    "v": "v/v/vlist_persistent_sequence.v",
    "zig": "zig/v/vlist_persistent_sequence.zig",
}


def static_issues() -> list[str]:
    metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if metadata.get("algorithm") != "vlist_persistent_sequence":
        issues.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        issues.append("inventory language map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            issues.append(f"missing language source: {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    return issues
