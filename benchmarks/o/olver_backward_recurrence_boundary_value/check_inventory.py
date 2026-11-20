"""Static package-path, bounds, and workload inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/o/olver_backward_recurrence_boundary_value.c",
    "c3": ROOT / "c3/o/olver_backward_recurrence_boundary_value.c3",
    "cpp": ROOT / "cpp/o/olver_backward_recurrence_boundary_value.cpp",
    "elisa": ROOT / "elisa/o/olver_backward_recurrence_boundary_value.elisa",
    "mojo": ROOT / "mojo/o/olver_backward_recurrence_boundary_value.mojo",
    "nim": ROOT / "nim/o/olver_backward_recurrence_boundary_value.nim",
    "odin": ROOT / "odin/o/olver_backward_recurrence_boundary_value.odin",
    "rust": ROOT / "rust/o/olver_backward_recurrence_boundary_value.rs",
    "v": ROOT / "v/o/olver_backward_recurrence_boundary_value.v",
    "zig": ROOT / "zig/o/olver_backward_recurrence_boundary_value.zig",
}
EXPECTED_CASES = {
    "inhomogeneous_cutoff_at_max", "zero_minimum_selects_first_endpoint",
    "maximum_frame_and_output", "no_cutoff_by_bounded_limit",
    "zero_homogeneous_product", "one_element_short_output",
    "invalid_m_before_output_error", "invalid_zero_tolerance",
    "invalid_coefficient_bound", "maximum_parseable_trailing_value",
    "null_input", "valid_null_output", "valid_zero_output_capacity",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    artifacts = ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                 "workload.json", "primary_oracle.py", "independent_oracle.py",
                 "verify_workload.py", "check_inventory.py", "__init__.py")
    for artifact in artifacts:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing artifact {artifact}")
    for language, source_path in SOURCES.items():
        if not source_path.is_file():
            issues.append(f"missing {source_path.relative_to(ROOT)}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "olver_backward_recurrence_boundary_value" not in source:
            issues.append(f"missing exported symbol in {source_path.relative_to(ROOT)}")
        if language == "elisa" and ("view[f64]" not in source or "UnsafePointer" in source or "*f64" in source):
            issues.append("Elisa internals should use bounded views behind the FFI boundary")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid metadata JSON: {error}"]
    expected_paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if (inventory.get("algorithm") != "olver_backward_recurrence_boundary_value"
            or set(inventory.get("native_paths", [])) != expected_paths):
        issues.append("inventory identity or native paths differ")
    if (workload.get("abi") != "float64_slice_io"
            or workload.get("input", {}).get("maximum_valid_input_length") != 52
            or workload.get("input", {}).get("maximum_parseable_input_length") != 53
            or workload.get("output", {}).get("maximum_elements") != 10
            or workload.get("workspace", {}).get("elements") != 10):
        issues.append("workload bounds differ from package contract")
    cases = workload.get("cases", []) + workload.get("abi_cases", [])
    ids = {case.get("id") for case in cases if isinstance(case, dict)}
    if ids != EXPECTED_CASES:
        issues.append("fixture IDs differ from the reviewed set")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values, length = case.get("input_values"), case.get("input_length")
        if (not isinstance(values, list) or type(length) is not int
                or (not case.get("input_is_null", False) and length != len(values))
                or length > 53):
            issues.append(f"invalid input framing for {case.get('id')}")
            continue
        output = case.get("expected_output")
        result = case.get("expected_result")
        if (not isinstance(output, list) or not isinstance(result, int)
                or (result >= 0 and len(output) != result)
                or (result < 0 and output)):
            issues.append(f"invalid expected output framing for {case.get('id')}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    errors = static_issues()
    if errors:
        raise SystemExit("\n".join(errors))
