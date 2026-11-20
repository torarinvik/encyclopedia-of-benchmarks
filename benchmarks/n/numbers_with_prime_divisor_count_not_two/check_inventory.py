"""Static source inventory; deliberately does not build or run language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "numbers_with_prime_divisor_count_not_two"
INPUT_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input_opt == null",
}
OUTPUT_GUARDS = {
    "c": "output == NULL",
    "c3": "output == null",
    "cpp": "output == nullptr",
    "elisa": "output.is_null()",
    "mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
    "nim": "output == nil",
    "odin": "output == nil",
    "rust": "output.is_null()",
    "v": "output == nil",
    "zig": "output_opt == null",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("algorithm identifier or symbol differs from package contract")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs from byte-output contract")
    if inventory.get("workspace_bytes") != 4096:
        issues.append("inventory workspace differs from the 4096-byte cap")
    if inventory.get("maximum_output_bytes") != 128:
        issues.append("inventory output bound differs from the 128-byte cap")
    languages = inventory.get("languages", {})
    if set(languages) != set(INPUT_GUARDS):
        issues.append("inventory must list exactly the ten supported language ports")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package README: {error}"]
    for language, relative in languages.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if INPUT_GUARDS.get(language) not in source:
            issues.append(f"null-input guard missing from {relative}")
        if OUTPUT_GUARDS.get(language) not in source:
            issues.append(f"null-output guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link differs from inventory for {language}")
    elisa_path = ROOT / languages.get("elisa", "")
    if elisa_path.is_file():
        elisa_source = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in elisa_source or "*i64" in elisa_source:
            issues.append("Elisa should use bounded views behind the exported FFI boundary")
    for artifact in inventory.get("metadata", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
