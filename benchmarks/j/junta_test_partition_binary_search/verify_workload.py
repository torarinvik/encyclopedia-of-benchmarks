"""Source-only workload/reference reconciler; intentionally not run here."""
from __future__ import annotations

import json
import struct
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    ROUNDS,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent


def workload_issues(workload: dict | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("algorithm") != "junta_test_partition_binary_search"
            or workload.get("function_symbol") != "junta_test_partition_binary_search"
            or workload.get("abi") != "i64_array_bytes_output"):
        return ["workload identity or ABI differs from the package"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("n_range") != [1, MAX_N]
            or input_spec.get("fixed_k") != 1
            or input_spec.get("fixed_round_count") != ROUNDS
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or WORKSPACE_BYTES != MAX_WORKSPACE_BYTES):
        issues.append("workload bounds/workspace differ from the references")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    saw_max_frame = False
    saw_max_parseable = False
    saw_max_output = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload case is not an object")
            continue
        name = case.get("id")
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        expected_values = case.get("expected_output_values")
        if (not isinstance(name, str) or name in seen
                or not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or type(length) is not int
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or not isinstance(expected_values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in expected_values)
                or input_is_null and values
                or not input_is_null and length != len(values)):
            issues.append(f"{name}: malformed fixture framing")
            continue
        seen.add(name)
        if not input_is_null and length == MAX_VALID_INPUT_LENGTH:
            saw_max_frame = True
        if not input_is_null and length == MAX_PARSEABLE_INPUT_LENGTH:
            saw_max_parseable = True
        if case.get("expected_result") == MAX_OUTPUT_BYTES:
            saw_max_output = True
        call = dict(capacity=capacity, input_is_null=input_is_null,
                    output_is_null=output_is_null, input_length=length)
        primary = primary_output(values, **call)
        independent = independent_output(values, **call)
        expected_bytes = b"".join(struct.pack("<q", value) for value in expected_values)
        if (primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1] != expected_bytes
                or primary[0] >= 0 and primary[0] != len(expected_bytes)):
            issues.append(f"{name}: pinned output disagrees with one or both references")
        pinned_hex = case.get("expected_output_hex")
        if not isinstance(pinned_hex, str) or pinned_hex != expected_bytes.hex():
            issues.append(f"{name}: expected_output_hex disagrees with expected_output_values")
    if not saw_max_frame:
        issues.append("no maximum valid input frame is pinned")
    if not saw_max_parseable:
        issues.append("no maximum parseable malformed frame is pinned")
    if not saw_max_output:
        issues.append("no maximum output case is pinned")
    return issues
