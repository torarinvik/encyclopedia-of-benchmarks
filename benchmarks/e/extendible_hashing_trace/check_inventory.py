"""Static source/inventory checks only; this file does not build language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "extendible_hashing_trace"
EXPECTED_LANGUAGES = {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}
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
    "zig": "input orelse return -1",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory identifier/symbol mismatch")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI mismatch")
    if set(inventory.get("languages", {})) != EXPECTED_LANGUAGES:
        issues.append("inventory must name exactly the ten supported languages")
    if inventory.get("bounds", {}).get("workspace_bytes") != 8192:
        issues.append("inventory workspace cap mismatch")
    for language, relative in inventory.get("languages", {}).items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"exported symbol missing in {relative}")
        if NULL_GUARDS.get(language) not in source:
            issues.append(f"null-input guard missing in {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source or "view[i64]" not in source):
            issues.append("Elisa should use a bounded view internally and keep pointer access at the ABI boundary")
    for artifact in inventory.get("metadata", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    input_bounds = workload.get("input", {})
    if input_bounds.get("maximum_valid_length") != 81 or input_bounds.get("maximum_parseable_length") != 82:
        issues.append("workload input bounds mismatch")
    if workload.get("output", {}).get("maximum_result") != inventory.get("bounds", {}).get("maximum_result"):
        issues.append("workload and inventory result caps differ")
    ids = [case.get("id") for case in workload.get("cases", []) if isinstance(case, dict)]
    if len(ids) != len(set(ids)):
        issues.append("workload fixture IDs are not unique")
    if set(ids) != set(inventory.get("fixture_ids", [])):
        issues.append("inventory fixture IDs differ from workload")
    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"malformed workload framing in {case.get('id')}")
        elif case.get("input_is_null", False) is not True and length != len(values):
            issues.append(f"declared frame length mismatch in {case.get('id')}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
