"""Static reconciliation of fixtures and both recurrence references."""

from __future__ import annotations

import json
import struct
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        INVALID_RESULT, MAX_COUNT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT,
        MAX_VALID_INPUT, MAX_WORKSPACE_BYTES, OUTPUT_ERROR,
        expected_output as primary_expected,
    )
    from .independent_oracle import expected_output as independent_expected
except ImportError:
    from primary_oracle import (
        INVALID_RESULT, MAX_COUNT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT,
        MAX_VALID_INPUT, MAX_WORKSPACE_BYTES, OUTPUT_ERROR,
        expected_output as primary_expected,
    )
    from independent_oracle import expected_output as independent_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "zero-count-valid-state-null-output", "one-step-hand-pinned-residue",
    "two-step-trace", "maximum-output-trace",
    "component-one-word-at-modulus-invalid", "component-two-word-at-modulus-invalid",
    "zero-component-one-state-invalid", "zero-component-two-state-invalid",
    "count-above-bound-invalid", "truncated-frame", "maximum-parseable-trailing-word",
    "null-input", "null-output-with-required-bytes", "one-byte-short-capacity",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["cases must be a list"]
    issues: list[str] = []
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or set(ids) != EXPECTED_IDS:
        issues.append("fixture identifiers differ from the pinned set")

    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "mrg32k3a_combined_recursive_generator"
            or workload.get("function_symbol") != "mrg32k3a_combined_recursive_generator"
            or workload.get("abi") != "i64_array_bytes_output"
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT
            or input_meta.get("count_range") != [0, MAX_COUNT]
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        issues.append("workload contract or resource metadata differs from references")

    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            issues.append("every fixture must contain input_values")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (type(length) is not int or type(input_null) is not bool
                or type(output_null) is not bool
                or (capacity is not None and type(capacity) is not int)):
            issues.append(f"invalid ABI metadata for {case.get('id')}")
            continue
        if input_null:
            if length != 0 or values:
                issues.append(f"null input framing is inconsistent for {case.get('id')}")
        elif length != len(values):
            issues.append(f"input length differs from value count for {case.get('id')}")

        primary = primary_expected(values, capacity, output_null, input_null, length)
        independent = independent_expected(values, capacity, output_null, input_null, length)
        if primary != independent:
            issues.append(f"references disagree for {case.get('id')}")
        expected_result, expected_bytes = primary
        if case.get("expected_result") != expected_result:
            issues.append(f"expected result differs for {case.get('id')}")
        expected_hex = case.get("expected_output_hex")
        if expected_hex is not None and expected_bytes.hex() != expected_hex:
            issues.append(f"expected output hex differs for {case.get('id')}")
        expected_words = case.get("expected_output_words")
        if expected_words is not None:
            if expected_result < 0 or expected_result % 8:
                issues.append(f"word fixture has an invalid result for {case.get('id')}")
            else:
                count = expected_result // 8
                decoded = list(struct.unpack("<" + "q" * count, expected_bytes))
                if decoded != expected_words:
                    issues.append(f"expected output words differ for {case.get('id')}")
        if expected_result > 0 and expected_hex is None and case.get("oracle_derived_output") is not True:
            issues.append(f"successful output is not pinned for {case.get('id')}")
        if expected_result <= 0 and expected_bytes:
            issues.append(f"error/empty result writes bytes for {case.get('id')}")

    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum = by_id.get("maximum-output-trace", {})
    if (maximum.get("input_length") != MAX_VALID_INPUT
            or maximum.get("output_capacity") != MAX_OUTPUT_BYTES
            or maximum.get("expected_result") != MAX_OUTPUT_BYTES
            or maximum.get("oracle_derived_output") is not True):
        issues.append("maximum fixture does not pin full input/output bounds")
    trailing = by_id.get("maximum-parseable-trailing-word", {})
    if (trailing.get("input_length") != MAX_PARSEABLE_INPUT
            or trailing.get("expected_result") != INVALID_RESULT):
        issues.append("maximum parseable trailing-word case is absent")
    if by_id.get("zero-count-valid-state-null-output", {}).get("expected_result") != 0:
        issues.append("valid zero-count/null-output behavior is absent")
    if by_id.get("null-output-with-required-bytes", {}).get("expected_result") != OUTPUT_ERROR:
        issues.append("null required-output error case is absent")
    if by_id.get("one-byte-short-capacity", {}).get("expected_result") != OUTPUT_ERROR:
        issues.append("short-capacity case is absent")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        issues.append("null-input ABI case is absent")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise AssertionError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
