"""Static package inventory checker; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/r/reverse_delete_mst.c",
    "c3": "c3/r/reverse_delete_mst.c3",
    "cpp": "cpp/r/reverse_delete_mst.cpp",
    "elisa": "elisa/r/reverse_delete_mst.elisa",
    "mojo": "mojo/r/reverse_delete_mst.mojo",
    "nim": "nim/r/reverse_delete_mst.nim",
    "odin": "odin/r/reverse_delete_mst.odin",
    "rust": "rust/r/reverse_delete_mst.rs",
    "v": "v/r/reverse_delete_mst.v",
    "zig": "zig/r/reverse_delete_mst.zig",
}


def static_issues() -> list[str]:
    """Return missing or mismatched package artifacts without compiling code."""
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read inventory: {error}"]
    errors: list[str] = []
    if metadata.get("algorithm") != "reverse_delete_mst":
        errors.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        errors.append("language source map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            errors.append(f"missing language source {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            errors.append(f"missing package file {relative}")
    return errors
