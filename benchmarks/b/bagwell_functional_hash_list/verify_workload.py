"""Static workload and dual-reference reconciliation; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        INVALID_RESULT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH, OUTPUT_ERROR, WORKSPACE_BYTES,
        expected_output as primary_expected,
    )
    from .independent_oracle import expected_output as independent_expected
except ImportError:
    from primary_oracle import (
        INVALID_RESULT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH, OUTPUT_ERROR, WORKSPACE_BYTES,
        expected_output as primary_expected,
    )
    from independent_oracle import expected_output as independent_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "empty-root-lookup", "collision-duplicate-shadow-and-snapshot",
    "cross-block-fallback-and-root-boundary", "level-8-16-32-boundaries",
    "maximum-frame-and-output", "trailing-word", "invalid-root",
    "key-out-of-range", "value-out-of-range", "short-output",
    "null-output", "invalid-before-null-output", "null-input",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["cases must be a list"]
    errors: list[str] = []
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or set(ids) != EXPECTED_IDS:
        errors.append("fixture identifiers must match the pinned workload set")
    if (workload.get("algorithm") != "bagwell_functional_hash_list"
            or workload.get("function_symbol") != "bagwell_functional_hash_list"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        errors.append("ABI or resource metadata differs from package constants")
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("every fixture must have an input_values array")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (type(length) is not int or type(input_null) is not bool
                or type(output_null) is not bool or type(capacity) is not int):
            errors.append(f"invalid ABI metadata for {case.get('id')}")
            continue
        if input_null:
            if length != 0 or values:
                errors.append(f"null input frame must be empty for {case.get('id')}")
        elif length != len(values):
            errors.append(f"input length mismatch for {case.get('id')}")
        primary = primary_expected(values, capacity, output_null, input_null, length)
        independent = independent_expected(values, capacity, output_null, input_null, length)
        if primary != independent:
            errors.append(f"references disagree for {case.get('id')}")
        result, payload = primary
        if case.get("expected_result") != result:
            errors.append(f"pinned result differs for {case.get('id')}")
        expected_hex = case.get("expected_output_hex")
        if expected_hex is not None and expected_hex.lower() != payload.hex():
            errors.append(f"pinned output bytes differ for {case.get('id')}")
        if result < 0 and payload:
            errors.append(f"error result writes bytes for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if by_id.get("maximum-frame-and-output", {}).get("input_length") != MAX_VALID_INPUT_LENGTH:
        errors.append("maximum fixture does not pin the full frame bound")
    if by_id.get("maximum-frame-and-output", {}).get("expected_result") != MAX_OUTPUT_BYTES:
        errors.append("maximum fixture does not pin the output bound")
    if by_id.get("short-output", {}).get("expected_result") != OUTPUT_ERROR:
        errors.append("short-output fixture is absent")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        errors.append("null-input fixture is absent")
    if by_id.get("level-8-16-32-boundaries", {}).get("input_values", [0])[0] != 25:
        errors.append("boundary fixture must cross both block transitions")
    return errors


def static_issues() -> list[str]:
    return workload_issues()
