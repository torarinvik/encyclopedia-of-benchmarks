"""Static pinned-output and oracle reconciliation helper; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PAYLOAD,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary,
)

PACKAGE = Path(__file__).resolve().parent


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    if (workload.get("algorithm") != "consistent_overhead_byte_stuffing"
            or workload.get("function_symbol") != "consistent_overhead_byte_stuffing"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_payload_bytes") != MAX_PAYLOAD
            or workload.get("input", {}).get("maximum_valid_input_values") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_values") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload identity or bounds differ from package constants")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if (not isinstance(values, list) or type(input_length) is not int
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or type(capacity) is not int or type(expected_result) is not int
                or not isinstance(expected_hex, str)
                or (input_is_null and (values or input_length != 0))
                or (not input_is_null and input_length != len(values))):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        try:
            expected = expected_result, bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid expected hex: {case_id}")
            continue
        args = (values, capacity, output_is_null, input_is_null, input_length)
        result_primary = primary(*args)
        result_independent = independent(*args)
        if result_primary != expected or result_independent != expected:
            issues.append(f"oracle mismatch: {case_id}")
        if result_primary != result_independent:
            issues.append(f"reference disagreement: {case_id}")
    required = {
        "empty-payload", "single-zero", "zero-between-runs",
        "exact-254-byte-block", "block-followed-by-one-byte", "null-input",
        "null-output-for-empty-payload", "short-output-for-empty-payload",
    }
    if not required <= seen:
        issues.append("required boundary and error fixtures are missing")
    return issues


static_issues = verify_workload
