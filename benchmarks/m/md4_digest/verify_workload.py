"""Static MD4 workload expansion and independent-reference reconciliation."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .primary_oracle import (
    INVALID_RESULT,
    MAX_MESSAGE_BYTES,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    OUTPUT_ERROR,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)
from .independent_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent
EXPECTED_CASES = {
    "empty", "short_binary", "padding_before_length_boundary_55",
    "padding_length_boundary_56", "one_block_end_63", "exact_block_64",
    "next_block_65", "maximum_message_4096", "missing_count_prefix",
    "negative_message_length", "message_length_above_limit", "truncated_message",
    "trailing_word", "negative_byte", "byte_above_range", "short_output_capacity",
    "null_output", "null_input", "invalid_input_precedes_null_output",
    "maximum_parseable_trailing_value",
}


def expand_cases(workload: Mapping[str, Any]) -> list[dict[str, Any]]:
    """Expand compact affine message recipes without changing the stored workload."""
    expanded: list[dict[str, Any]] = []
    for source in workload.get("cases", []):
        case = dict(source)
        if "message_generator" in case:
            generator = case.pop("message_generator")
            length = case.get("message_length")
            if (generator != {"kind": "affine_bytes", "multiplier": 37, "offset": 11}
                    or type(length) is not int or not 0 <= length <= MAX_MESSAGE_BYTES):
                raise ValueError(f"invalid compact MD4 message recipe: {case.get('id')}")
            message = [(37 * index + 11) & 0xFF for index in range(length)]
            values = [length, *message]
            if case.pop("append_trailing_word", False):
                values.append(0)
            case.pop("message_length")
            case["input_values"] = values
        case.setdefault("input_length", len(case.get("input_values", [])))
        expanded.append(case)
    return expanded


def verify_workload(workload: Mapping[str, Any] | None = None) -> list[str]:
    errors: list[str] = []
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if not isinstance(workload, Mapping):
        return ["workload must be a JSON object"]

    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "rfc1320-md4-bounded-message-i64-array-bytes-output-v1"
            or workload.get("algorithm") != "md4_digest"
            or workload.get("function_symbol") != "md4_digest"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("message_length_range") != [0, MAX_MESSAGE_BYTES]
            or workload.get("input", {}).get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_words") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"
            or not isinstance(cases, list)
            or set(case_ids) != EXPECTED_CASES
            or len(case_ids) != len(EXPECTED_CASES)
            or len(case_ids) != len(set(case_ids))):
        errors.append("MD4 workload metadata or fixture IDs differ from the bounded contract")
        return errors

    indexed = {case["id"]: case for case in cases}
    expanded = expand_cases(workload)
    expanded_by_id = {case["id"]: case for case in expanded}
    expected_lengths = {
        "empty": 0, "short_binary": 4,
        "padding_before_length_boundary_55": 55,
        "padding_length_boundary_56": 56, "one_block_end_63": 63,
        "exact_block_64": 64, "next_block_65": 65, "maximum_message_4096": 4096,
    }
    for case_id, message_length in expected_lengths.items():
        case = expanded_by_id[case_id]
        values = case["input_values"]
        if values[0] != message_length or len(values) != message_length + 1:
            errors.append(f"MD4 message boundary fixture is malformed: {case_id}")

    for case in expanded:
        case_id = case["id"]
        values = case.get("input_values")
        capacity = case.get("output_capacity", WORKSPACE_BYTES)
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        if not isinstance(values, list):
            errors.append(f"MD4 input values must be an array: {case_id}")
            continue
        primary = primary_output(values, capacity, output_is_null, input_is_null, input_length)
        independent = independent_output(values, capacity, output_is_null, input_is_null, input_length)
        if primary != independent:
            errors.append(f"MD4 references disagree: {case_id}")
        if case.get("expected_result") != primary[0]:
            errors.append(f"MD4 expected result mismatch: {case_id}")
        if primary[0] >= 0 and (primary[0] != MAX_OUTPUT_BYTES or len(primary[1]) != MAX_OUTPUT_BYTES):
            errors.append(f"MD4 digest width mismatch: {case_id}")
        if primary[0] < 0 and (primary[1] or primary[0] not in (INVALID_RESULT, OUTPUT_ERROR)):
            errors.append(f"MD4 error result contract mismatch: {case_id}")
        if "expected_output_hex" in indexed[case_id]:
            if indexed[case_id]["expected_output_hex"].lower() != primary[1].hex():
                errors.append(f"MD4 expected bytes mismatch: {case_id}")

    if expanded_by_id["short_output_capacity"].get("output_capacity") != 15:
        errors.append("MD4 short-capacity fixture is missing the one-byte-short case")
    if (expanded_by_id["null_input"].get("input_is_null") is not True
            or expanded_by_id["null_output"].get("output_is_null") is not True
            or expanded_by_id["invalid_input_precedes_null_output"].get("output_is_null") is not True
            or expanded_by_id["maximum_parseable_trailing_value"]["input_length"] != MAX_PARSEABLE_INPUT_LENGTH
            or expanded_by_id["maximum_parseable_trailing_value"]["expected_result"] != INVALID_RESULT):
        errors.append("MD4 ABI/error-precedence fixtures do not cover the declared boundaries")
    return errors


def main() -> int:
    errors = verify_workload()
    if errors:
        raise SystemExit("\n".join(errors))
    return 0
