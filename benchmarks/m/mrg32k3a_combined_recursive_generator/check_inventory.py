"""Static file/path inventory API; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "c": "c/m/mrg32k3a_combined_recursive_generator.c",
    "c3": "c3/m/mrg32k3a_combined_recursive_generator.c3",
    "cpp": "cpp/m/mrg32k3a_combined_recursive_generator.cpp",
    "elisa": "elisa/m/mrg32k3a_combined_recursive_generator.elisa",
    "mojo": "mojo/m/mrg32k3a_combined_recursive_generator.mojo",
    "nim": "nim/m/mrg32k3a_combined_recursive_generator.nim",
    "odin": "odin/m/mrg32k3a_combined_recursive_generator.odin",
    "rust": "rust/m/mrg32k3a_combined_recursive_generator.rs",
    "v": "v/m/mrg32k3a_combined_recursive_generator.v",
    "zig": "zig/m/mrg32k3a_combined_recursive_generator.zig",
}


def static_issues() -> list[str]:
    metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if metadata.get("algorithm") != "mrg32k3a_combined_recursive_generator":
        issues.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        issues.append("inventory language-source map differs")
    for relative in LANGUAGE_PATHS.values():
        if not (ROOT / relative).is_file():
            issues.append(f"missing language source: {relative}")
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise AssertionError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
