"""Static package inventory checks; this module never builds or runs ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "minimal_dominating_sets_permutation_graphs"
EXPECTED_LANGUAGES = {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input==null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("algorithm identifier or symbol differs from the package")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI differs from the scalar contract")
    if inventory.get("workspace_bytes") != 1_048_576:
        issues.append("inventory workspace differs from the 1 MiB cap")
    languages = inventory.get("languages", {})
    if set(languages) != EXPECTED_LANGUAGES:
        issues.append("inventory must list exactly the ten supported languages")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read README: {error}"]
    for language, relative in languages.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if language in NULL_GUARDS and NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard text missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README path differs from inventory for {language}")
    for artifact in inventory.get("metadata", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
