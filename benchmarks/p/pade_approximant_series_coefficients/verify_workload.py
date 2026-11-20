"""Static workload/reference agreement helper; do not run during drafting."""

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
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity/ABI differs from package references")
    if (workload.get("input", {}).get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != primary_oracle.MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES):
        issues.append("workload bounds differ from package references")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["cases must be a list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("case list contains a non-object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate case ID {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or (not is_null and length != len(values))):
            issues.append(f"input frame mismatch in {case_id}")
            continue
        args = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": is_null,
            "input_length": length,
        }
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        for name, oracle in (("primary", primary_oracle), ("independent", independent_oracle)):
            result, output = oracle.expected_output(values, **args)
            actual_hex = output.hex()
            if result != expected_result or actual_hex != expected_hex:
                issues.append(f"{name} output differs for {case_id}")
    required = {
        "linear_pade_11", "geometric_series_pade_11", "nontrivial_pade_21",
        "nontrivial_pade_22", "maximum_degrees_and_output",
        "maximum_output_one_byte_short", "singular_denominator_system",
        "singular_after_capacity_check", "null_output", "invalid_degree_before_output_error",
        "invalid_q_above_p", "invalid_noncanonical_coefficient", "invalid_short_frame",
        "maximum_parseable_trailing_word", "null_input",
    }
    if seen != required:
        issues.append("fixture IDs differ from reviewed workload inventory")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
