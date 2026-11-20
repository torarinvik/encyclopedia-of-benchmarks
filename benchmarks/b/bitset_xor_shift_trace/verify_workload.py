"""Static workload/reference consistency checks for the packed bitset trace."""

from __future__ import annotations

import struct

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    MAX_BITS,
    MAX_OPERATIONS,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)


def verify_workload(workload: dict) -> list[str]:
    issues: list[str] = []
    if (workload.get("algorithm") != "bitset_xor_shift_trace"
            or workload.get("function_symbol") != "bitset_xor_shift_trace"
            or workload.get("abi") != "i64_array_bytes_output"):
        return ["workload identity or ABI differs from the package"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("bit_count_range") != [1, MAX_BITS]
            or input_spec.get("operation_count_range") != [0, MAX_OPERATIONS]
            or output_spec.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload bounds or workspace differ from the oracle profile")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    ids: set[str] = set()
    saw_max_frame = False
    saw_max_output = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload case is not an object")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        expected_counts = case.get("expected_output_values")
        if (not isinstance(case_id, str) or case_id in ids
                or not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(input_length) is not int
                or type(input_is_null) is not bool
                or type(output_is_null) is not bool
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
                or not isinstance(expected_counts, list)
                or any(type(value) is not int or not 0 <= value <= MAX_BITS
                       for value in expected_counts)
                or input_is_null and values
                or not input_is_null and input_length != len(values)):
            issues.append(f"{case_id}: malformed case framing")
            continue
        ids.add(case_id)
        if len(values) == MAX_VALID_INPUT_LENGTH:
            saw_max_frame = True
        if case.get("expected_result") == MAX_OUTPUT_BYTES:
            saw_max_output = True
        call = dict(capacity=capacity, output_is_null=output_is_null,
                    input_is_null=input_is_null, input_length=input_length)
        primary = primary_output(values, **call)
        independent = independent_output(values, **call)
        expected_bytes = b"".join(struct.pack("<i", count) for count in expected_counts)
        if (primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1] != expected_bytes
                or primary[0] >= 0 and primary[0] != len(expected_bytes)):
            issues.append(f"{case_id}: expected result/counts differ from the two references")
    if not saw_max_frame:
        issues.append("workload has no maximum-length valid input frame")
    if not saw_max_output:
        issues.append("workload has no maximum-output fixture")
    return issues
