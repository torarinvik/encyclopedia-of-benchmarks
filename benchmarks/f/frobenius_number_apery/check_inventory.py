"""Static source inventory for frobenius_number_apery; does not build ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "frobenius_number_apery"
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
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
        return [f"cannot read inventory metadata: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("algorithm or exported symbol differs from package identifier")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI differs from the scalar contract")
    if inventory.get("workspace_bytes") != 256:
        issues.append("inventory workspace differs from the 256-byte cap")
    languages = inventory.get("languages", {})
    if len(languages) != 10:
        issues.append("inventory must list exactly ten language ports")
    for language, relative in languages.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if language in NULL_GUARDS and NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in (PACKAGE / "README.md").read_text(encoding="utf-8"):
            issues.append(f"README path mismatch for {language}")
    elisa_path = ROOT / languages.get("elisa", "")
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in elisa or "*i64" in elisa:
            issues.append("Elisa should keep raw pointers out of the implementation")
    for artifact in inventory.get("metadata", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package metadata: {artifact}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
