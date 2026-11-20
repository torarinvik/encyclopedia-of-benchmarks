"""Metadata-only workload/reference reconciliation; native code is not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent
SYMBOL = "digital_filter_direct_form_ii_transposed"
REQUIRED_CASES = {
    "order_zero_negated_feedthrough",
    "first_order_unit_feedback_state_persists_within_call",
    "second_order_two_sample_feedforward_delay",
    "first_order_feedback_only_tail",
    "feedforward_and_feedback_terms_combine",
    "maximum_order_and_sample_count_short_capacity",
    "empty_sequence_accepts_null_output",
    "invalid_a0",
    "coefficient_outside_small_exact_domain",
    "sample_outside_domain",
    "short_frame",
    "trailing_word",
    "valid_input_short_output_capacity",
    "valid_nonempty_null_output",
    "invalid_input_precedes_output_error",
    "null_input",
}


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs")
    if (workload.get("input", {}).get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_output_bytes") != primary_oracle.MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES):
        issues.append("workload bounds differ from primary reference")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture must have a string id")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(capacity) is not int or type(expected) is not int
                or type(input_is_null) is not bool or type(output_is_null) is not bool):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        primary = primary_oracle.expected_output(
            values, capacity, output_is_null, input_is_null, length)
        independent = independent_oracle.expected_output(
            values, capacity, output_is_null, input_is_null, length)
        if primary != independent:
            issues.append(f"references disagree for {case_id}")
        if primary[0] != expected:
            issues.append(f"pinned result differs for {case_id}")
        expected_hex = case.get("expected_output_hex")
        if not isinstance(expected_hex, str) or primary[1].hex() != expected_hex:
            issues.append(f"pinned output differs for {case_id}")
    if seen != REQUIRED_CASES:
        issues.append(f"fixture IDs differ: {sorted(seen ^ REQUIRED_CASES)}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
