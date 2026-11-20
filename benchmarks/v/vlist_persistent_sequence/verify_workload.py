"""Static workload/reference reconciliation API; intentionally unrun."""

from __future__ import annotations

import json
import struct
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        INVALID_RESULT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT,
        MAX_VALID_INPUT, MAX_WORKSPACE_BYTES, OUTPUT_ERROR,
        expected_output as primary_expected,
    )
    from .independent_oracle import expected_output as independent_expected
except ImportError:
    from primary_oracle import (
        INVALID_RESULT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT,
        MAX_VALID_INPUT, MAX_WORKSPACE_BYTES, OUTPUT_ERROR,
        expected_output as primary_expected,
    )
    from independent_oracle import expected_output as independent_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "small-saved-roots-and-tail", "empty-root-length", "singleton-tail-becomes-empty",
    "maximum-linear-growth-and-persistent-queries", "short-output-capacity", "null-output",
    "malformed-before-null-output", "branch-cons-outside-linear-build-profile",
    "cons-after-query-phase", "empty-cdr-invalid", "index-out-of-range", "trailing-word",
    "null-input",
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
        errors.append("fixture identifiers must match the unique pinned workload set")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "vlist_persistent_sequence"
            or workload.get("function_symbol") != "vlist_persistent_sequence"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        errors.append("workload ABI or resource metadata differs from package constants")
    complexity = workload.get("complexity", {})
    complexity_fields = (
        ("primary_time", "O(Q"),
        ("primary_auxiliary_space", "O(N+Q)"),
        ("independent_reference_time", "O(Q*N)"),
        ("independent_reference_auxiliary_space", "O(Q*N)"),
    )
    if not isinstance(complexity, dict) or any(
        not isinstance(complexity.get(field), str)
        or not complexity[field].startswith(prefix)
        for field, prefix in complexity_fields
    ):
        errors.append("complexity metadata is absent or inconsistent")
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
        expected_result, expected_bytes = primary
        if case.get("expected_result") != expected_result:
            errors.append(f"pinned result differs for {case.get('id')}")
        expected_words = case.get("expected_output_words")
        if not isinstance(expected_words, list):
            errors.append(f"expected_output_words is missing for {case.get('id')}")
            continue
        if expected_result > 0:
            word_count = expected_result // 8
            decoded = list(struct.unpack("<" + "q" * word_count, expected_bytes))
            if expected_result % 8 or decoded != expected_words:
                errors.append(f"pinned output words differ for {case.get('id')}")
        elif expected_bytes or expected_words:
            errors.append(f"error fixture must have empty output for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum = by_id.get("maximum-linear-growth-and-persistent-queries", {})
    if (maximum.get("input_length") != MAX_VALID_INPUT
            or maximum.get("output_capacity") != MAX_OUTPUT_BYTES
            or maximum.get("expected_result") != MAX_OUTPUT_BYTES
            or len(maximum.get("expected_output_words", [])) != 48):
        errors.append("maximum fixture does not pin input and output bounds")
    if by_id.get("short-output-capacity", {}).get("expected_result") != OUTPUT_ERROR:
        errors.append("short-capacity fixture does not pin output failure")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        errors.append("null input ABI fixture is absent")
    if by_id.get("branch-cons-outside-linear-build-profile", {}).get("expected_result") != INVALID_RESULT:
        errors.append("out-of-profile branch-cons framing must be rejected")
    return errors
