"""Static inventory review. This module reads source and metadata only."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "minkowski_question_mark_rational"
PORTS = {
    "c": "c/m/minkowski_question_mark_rational.c",
    "c3": "c3/m/minkowski_question_mark_rational.c3",
    "cpp": "cpp/m/minkowski_question_mark_rational.cpp",
    "elisa": "elisa/m/minkowski_question_mark_rational.elisa",
    "mojo": "mojo/m/minkowski_question_mark_rational.mojo",
    "nim": "nim/m/minkowski_question_mark_rational.nim",
    "odin": "odin/m/minkowski_question_mark_rational.odin",
    "rust": "rust/m/minkowski_question_mark_rational.rs",
    "v": "v/m/minkowski_question_mark_rational.v",
    "zig": "zig/m/minkowski_question_mark_rational.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    package_files = (
        "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py", "check_inventory.py",
    )
    for name in package_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol: {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "view[i64]" not in source):
            issues.append("Elisa port must use a bounded borrowed input view")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or native port list differs")
    bounds = inventory.get("bounds", {})
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (bounds.get("maximum_denominator") != 1_000_000
            or bounds.get("maximum_partial_quotient_sum") != 60
            or bounds.get("maximum_valid_input_length") != 2
            or bounds.get("maximum_parseable_input_length") != 3
            or bounds.get("maximum_output_bytes") != 16
            or bounds.get("maximum_output_exponent") != 59
            or bounds.get("workspace_bytes") != 128
            or input_spec.get("maximum_valid_length") != 2
            or input_spec.get("maximum_parseable_length") != 3
            or input_spec.get("maximum_partial_quotient_sum") != 60
            or output_spec.get("maximum_bytes") != 16
            or workload.get("workspace", {}).get("bytes") != 128):
        issues.append("inventory/workload bounds differ from the profile")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
