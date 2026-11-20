"""Fixture/reference agreement helpers for the bounded Olver profile."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("algorithm") != primary_oracle.ALGORITHM
            or workload.get("function_symbol") != primary_oracle.ALGORITHM
            or workload.get("abi") != "float64_slice_io"):
        issues.append("workload identity or ABI differs from references")
    if (workload.get("input", {}).get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != primary_oracle.MAX_OUTPUT_ELEMENTS
            or workload.get("workspace", {}).get("elements") != primary_oracle.WORKSPACE_ELEMENTS):
        issues.append("workload bounds differ from references")
    expected = {
        "inhomogeneous_cutoff_at_max", "zero_minimum_selects_first_endpoint",
        "maximum_frame_and_output", "no_cutoff_by_bounded_limit",
        "zero_homogeneous_product", "one_element_short_output",
        "invalid_m_before_output_error", "invalid_zero_tolerance",
        "invalid_coefficient_bound", "maximum_parseable_trailing_value",
        "null_input", "valid_null_output", "valid_zero_output_capacity",
    }
    seen: set[str] = set()
    for case in workload.get("cases", []) + workload.get("abi_cases", []):
        if not isinstance(case, dict):
            issues.append("workload contains a non-object fixture")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate fixture ID {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or (not is_null and length != len(values))
                or length > primary_oracle.MAX_PARSEABLE_INPUT_LENGTH):
            issues.append(f"input framing mismatch for {case_id}")
            continue
        args = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": is_null,
            "input_length": length,
        }
        for name, oracle in (("primary", primary_oracle), ("independent", independent_oracle)):
            result, output = oracle.expected_output(values, **args)
            if result != case.get("expected_result"):
                issues.append(f"{name} result differs for {case_id}")
            expected_output = case.get("expected_output")
            actual_output = list(output)
            if (not isinstance(expected_output, list) or len(actual_output) != len(expected_output)
                    or any(abs(float(x) - float(y)) > 1e-9 + 1e-12 * abs(float(y))
                           for x, y in zip(actual_output, expected_output))):
                issues.append(f"{name} output differs for {case_id}")
    if seen != expected:
        issues.append("fixture IDs differ from the reviewed set")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
