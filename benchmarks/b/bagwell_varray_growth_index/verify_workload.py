"""Static agreement check for the bounded VArray workload and references."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]

    if workload.get("algorithm") != "bagwell_varray_growth_index":
        issues.append("algorithm name mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    representation = workload.get("representation", {})
    if (representation.get("initial_header") != 0
            or representation.get("header_transitions") != [64, 320]
            or "follow previous_level_link" not in representation.get("query_path", "")):
        issues.append("linked-level representation metadata mismatch")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    if input_contract.get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT:
        issues.append("maximum parseable input length mismatch")
    if output_contract.get("maximum_output_bytes") != primary_oracle.MAX_OUTPUT_BYTES:
        issues.append("maximum output byte count mismatch")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.MAX_WORKSPACE_BYTES:
        issues.append("workspace bound mismatch")

    cases = workload.get("cases", [])
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        if case_id in seen:
            issues.append(f"{case_id}: duplicate case ID")
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be an array")
            continue
        input_length = case.get("input_length")
        if type(input_length) is not int or input_length != len(values):
            issues.append(f"{case_id}: input_length does not match input_values")
            continue
        try:
            expected = (
                int(case["expected_result"]),
                bytes.fromhex(case["expected_output_hex"]),
            )
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"{case_id}: malformed expected output: {error}")
            continue
        output_capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        primary = primary_oracle.expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length
        )
        independent = independent_oracle.expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length
        )
        if primary != expected:
            issues.append(f"{case_id}: primary reference disagrees with fixture")
        if independent != expected:
            issues.append(f"{case_id}: independent reference disagrees with fixture")
        if primary != independent:
            issues.append(f"{case_id}: references disagree")
        if len(expected[1]) > primary_oracle.MAX_OUTPUT_BYTES:
            issues.append(f"{case_id}: expected output exceeds declared maximum")

    if not cases:
        issues.append("workload has no cases")
    required_ids = {
        "empty_array_has_zero_probe_header",
        "all_growth_boundaries_and_maximum_n",
        "maximum_query_count_and_output_capacity_boundary",
        "maximum_parseable_frame_with_max_n_q_and_trailing_word",
        "null_input",
        "valid_input_null_output",
    }
    if not required_ids.issubset(seen):
        issues.append("workload is missing one or more required boundary/null fixtures")
    return issues
