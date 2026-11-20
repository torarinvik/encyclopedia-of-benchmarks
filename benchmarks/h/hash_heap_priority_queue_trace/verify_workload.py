"""Static workload/reference reconciliation for the hash-heap profile."""
from __future__ import annotations

import json
import struct
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES, expected_output as primary_output,
    )
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES, expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "zero-operations", "ordered-buckets-and-stable-ties", "empty-query-status",
    "maximum-frame-and-output", "maximum-output-one-byte-short",
    "maximum-parseable-trailing-word", "null-input", "null-output",
}


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "hash_heap_priority_queue_trace"
            or workload.get("function_symbol") != "hash_heap_priority_queue_trace"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("operation_count_range") != [0, 64]
            or input_spec.get("universe_range") != [1, 128]
            or input_spec.get("bucket_count_range") != [1, 8]
            or input_spec.get("hash_mapping") != "floor(key*B/U")
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload bounds differ from the profile constants")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("fixture is not an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate fixture ID: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"input framing mismatch: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"input exceeds parseable bound: {case_id}")
            continue
        null_input = case.get("input_is_null", False)
        null_output = case.get("output_is_null", False)
        if type(null_input) is not bool or type(null_output) is not bool:
            issues.append(f"null-pointer framing is not boolean: {case_id}")
            continue
        capacity = case.get("output_capacity", WORKSPACE_BYTES)
        kwargs = {
            "capacity": capacity,
            "output_is_null": null_output,
            "input_is_null": null_input,
            "input_length": case["input_length"],
        }
        primary = primary_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        expected_words = case.get("expected_output_words")
        expected_hex = case.get("expected_output_hex")
        if (primary != independent or primary[0] != case.get("expected_result")
                or not isinstance(expected_words, list)
                or any(type(word) is not int for word in expected_words)
                or not isinstance(expected_hex, str)):
            issues.append(f"fixture/reference mismatch: {case_id}")
            continue
        encoded = struct.pack("<" + "q" * len(expected_words), *expected_words)
        if primary[1] != encoded:
            issues.append(f"fixture output words differ: {case_id}")
        try:
            encoded_hex = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"fixture output hex is malformed: {case_id}")
            continue
        if encoded_hex != primary[1]:
            issues.append(f"fixture output hex differs: {case_id}")
    if not REQUIRED_CASES.issubset(seen):
        issues.append("workload omits a required max-frame/output or ABI case")
    if not any(len(case.get("input_values", [])) == MAX_VALID_INPUT_LENGTH
               and case.get("expected_result") == MAX_OUTPUT_BYTES for case in cases):
        issues.append("workload has no successful maximum-frame/output fixture")
    return issues


def verify() -> list[str]:
    return workload_issues()


if __name__ == "__main__":
    print("static hash-heap workload reconciliation")
