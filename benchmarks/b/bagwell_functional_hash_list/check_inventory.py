"""Static metadata/path inventory; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/b/bagwell_functional_hash_list.c",
    "c3": "c3/b/bagwell_functional_hash_list.c3",
    "cpp": "cpp/b/bagwell_functional_hash_list.cpp",
    "elisa": "elisa/b/bagwell_functional_hash_list.elisa",
    "mojo": "mojo/b/bagwell_functional_hash_list.mojo",
    "nim": "nim/b/bagwell_functional_hash_list.nim",
    "odin": "odin/b/bagwell_functional_hash_list.odin",
    "rust": "rust/b/bagwell_functional_hash_list.rs",
    "v": "v/b/bagwell_functional_hash_list.v",
    "zig": "zig/b/bagwell_functional_hash_list.zig",
}


def static_issues() -> list[str]:
    metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if metadata.get("algorithm") != "bagwell_functional_hash_list":
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
