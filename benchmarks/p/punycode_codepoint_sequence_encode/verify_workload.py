"""Static workload/reference reconciliation API; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from . import MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_WORDS, MAX_VALID_INPUT_WORDS, WORKSPACE_BYTES
    from .independent_oracle import expected_output as independent_expected
    from .primary_oracle import expected_output as primary_expected
except ImportError:
    from __init__ import MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_WORDS, MAX_VALID_INPUT_WORDS, WORKSPACE_BYTES
    from independent_oracle import expected_output as independent_expected
    from primary_oracle import expected_output as primary_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "empty-sequence", "all-basic-keeps-required-delimiter", "nonbasic-only",
    "basic-and-nonbasic", "maximum-all-basic-delimiter", "surrogate-is-invalid",
    "above-unicode-range-is-invalid", "trailing-word-is-invalid", "short-capacity",
    "null-output", "null-input",
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
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "punycode_codepoint_sequence_encode"
            or workload.get("function_symbol") != "punycode_codepoint_sequence_encode"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_WORDS
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_WORDS
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        errors.append("workload ABI or resource metadata differs from package constants")
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("every fixture must contain an input_values array")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (type(length) is not int or type(input_null) is not bool
                or type(output_null) is not bool or type(capacity) is not int):
            errors.append(f"invalid ABI metadata for fixture {case.get('id')}")
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
        pinned_hex = case.get("expected_output_hex")
        if not isinstance(pinned_hex, str) or "".join(pinned_hex.split()) != payload.hex():
            errors.append(f"pinned payload differs for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    for case_id in ("empty-sequence", "all-basic-keeps-required-delimiter",
                    "basic-and-nonbasic", "nonbasic-only"):
        if case_id not in by_id:
            errors.append(f"RFC delimiter/scalar fixture is absent: {case_id}")
    if by_id.get("all-basic-keeps-required-delimiter", {}).get("expected_output_hex", "").endswith("2d") is not True:
        errors.append("all-basic fixture must retain the RFC delimiter")
    maximum = by_id.get("maximum-all-basic-delimiter", {})
    if (maximum.get("input_length") != MAX_VALID_INPUT_WORDS
            or len(maximum.get("input_values", [])) != MAX_VALID_INPUT_WORDS
            or maximum.get("expected_result") != 33):
        errors.append("maximum all-basic fixture must include its delimiter")
    if by_id.get("short-capacity", {}).get("expected_result") != -2:
        errors.append("short-capacity fixture is absent")
    if by_id.get("null-output", {}).get("output_is_null") is not True:
        errors.append("null-output fixture is absent")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        errors.append("null-input fixture is absent")
    return errors
