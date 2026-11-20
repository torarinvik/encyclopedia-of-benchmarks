"""Static-only inventory checks for the Gregorian ordinal-date package."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]


def static_issues() -> list[str]:
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    issues: list[str] = []
    if inventory.get("algorithm") != "gregorian_daycount_to_ordinal_date":
        issues.append("inventory algorithm mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    languages = inventory.get("languages", {})
    if set(languages) != {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}:
        issues.append("inventory must list exactly ten supported languages")
    for language, relative in languages.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif "gregorian_daycount_to_ordinal_date" not in source.read_text():
            issues.append(f"symbol absent from {relative}")
    for relative in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    return issues
