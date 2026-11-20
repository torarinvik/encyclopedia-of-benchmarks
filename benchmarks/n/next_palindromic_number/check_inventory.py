"""Static package-file and inventory review; never builds language ports."""

from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/n/next_palindromic_number.c",
    "c3": "c3/n/next_palindromic_number.c3",
    "cpp": "cpp/n/next_palindromic_number.cpp",
    "elisa": "elisa/n/next_palindromic_number.elisa",
    "mojo": "mojo/n/next_palindromic_number.mojo",
    "nim": "nim/n/next_palindromic_number.nim",
    "odin": "odin/n/next_palindromic_number.odin",
    "rust": "rust/n/next_palindromic_number.rs",
    "v": "v/n/next_palindromic_number.v",
    "zig": "zig/n/next_palindromic_number.zig",
}


def inventory_issues() -> list[str]:
    metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    if metadata.get("algorithm") != "next_palindromic_number":
        errors.append("inventory algorithm name differs")
    declared = metadata.get("language_sources", {})
    if declared != LANGUAGE_PATHS:
        errors.append("inventory language source map differs from the bounded ten-port map")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            errors.append(f"missing language source: {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            errors.append(f"missing package artifact: {relative}")
    return errors


def static_issues() -> list[str]:
    return inventory_issues() + workload_issues()
