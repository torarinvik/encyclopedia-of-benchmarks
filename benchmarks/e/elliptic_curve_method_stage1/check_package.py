"""Static source inventory for the bounded ECM stage-1 package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/e/elliptic_curve_method_stage1.c",
    "c3": ROOT / "c3/e/elliptic_curve_method_stage1.c3",
    "cpp": ROOT / "cpp/e/elliptic_curve_method_stage1.cpp",
    "elisa": ROOT / "elisa/e/elliptic_curve_method_stage1.elisa",
    "mojo": ROOT / "mojo/e/elliptic_curve_method_stage1.mojo",
    "nim": ROOT / "nim/e/elliptic_curve_method_stage1.nim",
    "odin": ROOT / "odin/e/elliptic_curve_method_stage1.odin",
    "rust": ROOT / "rust/e/elliptic_curve_method_stage1.rs",
    "v": ROOT / "v/e/elliptic_curve_method_stage1.v",
    "zig": ROOT / "zig/e/elliptic_curve_method_stage1.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
EXPECTED_CASES = {
    "prime_curve_no_factor",
    "composite_point_not_stage1_smooth",
    "stage1_double_exposes_seven",
    "higher_bound_keeps_detected_factor",
    "even_modulus_invalid",
    "repeated_prime_factor_invalid",
    "singular_curve_invalid",
    "point_not_on_curve_invalid",
    "bound_out_of_range",
    "trailing_word_invalid",
    "null_input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    for language, source_path in SOURCES.items():
        if not source_path.is_file():
            issues.append(f"missing {source_path.relative_to(ROOT)}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "elliptic_curve_method_stage1" not in source:
            issues.append(f"{source_path.relative_to(ROOT)} lacks the exported symbol")
        if NULL_GUARDS[language] not in source:
            issues.append(f"{source_path.relative_to(ROOT)} lacks the documented null-input guard")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source):
            issues.append("Elisa must keep internal state in safe fixed storage and views")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            cases = workload.get("cases")
            case_ids = (
                {case.get("id") for case in cases}
                if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                else set()
            )
            if (
                workload.get("algorithm") != "elliptic_curve_method_stage1"
                or workload.get("function_symbol") != "elliptic_curve_method_stage1"
                or workload.get("abi") != "i64_array_scalar"
                or workload.get("input", {}).get("maximum_valid_input_length") != 5
                or workload.get("input", {}).get("maximum_parseable_input_length") != 6
                or workload.get("workspace", {}).get("bytes") != 1024
            ):
                issues.append("workload metadata differs from its bounded scalar contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload cases differ from the reviewed fixture inventory")
    return issues
