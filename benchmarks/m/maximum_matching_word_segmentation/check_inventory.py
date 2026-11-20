"""Static package/source inventory validator; intentionally not executed here."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = PACKAGE_DIR.parents[2]
EXPECTED_SYMBOL = "maximum_matching_word_segmentation"


def static_issues() -> list[str]:
    inventory = json.loads((PACKAGE_DIR / "inventory.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if inventory.get("algorithm") != EXPECTED_SYMBOL:
        issues.append("inventory algorithm does not match the exported symbol")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI does not match the package contract")
    implementations = inventory.get("implementations", {})
    if len(implementations) != 10:
        issues.append("inventory must list ten language sources")
    for language, relative_path in implementations.items():
        source = REPOSITORY_ROOT / relative_path
        if not source.is_file():
            issues.append(f"missing {language} source: {relative_path}")
        elif EXPECTED_SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"exported symbol is missing from {relative_path}")
    for relative_path in inventory.get("references", []) + inventory.get("metadata", []):
        if not (PACKAGE_DIR / relative_path).is_file():
            issues.append(f"missing package file: {relative_path}")
    for reference in inventory.get("references", []):
        source = PACKAGE_DIR / reference
        if source.is_file() and "def expected_output(" not in source.read_text(encoding="utf-8"):
            issues.append(f"reference lacks expected_output(): {reference}")
    return issues


def main() -> int:
    issues = static_issues()
    if issues:
        for issue in issues:
            print(issue)
        return 1
    print("maximum_matching_word_segmentation package inventory is complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
