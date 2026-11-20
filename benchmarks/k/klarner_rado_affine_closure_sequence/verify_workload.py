"""Static metadata and oracle agreement for the bounded A005658 profile."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .primary_oracle import (
    INVALID_RESULT,
    MAX_INDEX,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_result as primary_result,
)
from .independent_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent
EXPECTED_CASES = {
    "first", "second", "third", "fourth", "eighth", "sixteenth",
    "thirty_second", "maximum", "zero_invalid", "negative_invalid",
    "above_maximum_invalid", "trailing_value_invalid", "empty_invalid",
    "null_input", "i64_min_invalid", "i64_max_invalid",
}


def verify_workload(workload: Mapping[str, Any] | None = None) -> list[str]:
    errors: list[str] = []
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if not isinstance(workload, Mapping):
        return ["workload must be a JSON object"]
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "klarner-rado-a005658-affine-closure-i64-array-scalar-v1"
            or workload.get("algorithm") != "klarner_rado_affine_closure_sequence"
            or workload.get("function_symbol") != "klarner_rado_affine_closure_sequence"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("index_range") != [1, MAX_INDEX]
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("valid_result_range") != [1, MAX_RESULT]
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or not isinstance(cases, list)
            or set(case_ids) != EXPECTED_CASES
            or len(case_ids) != len(EXPECTED_CASES)
            or len(case_ids) != len(set(case_ids))):
        errors.append("A005658 workload metadata or fixture IDs differ from the bounded contract")
        return errors

    published = {1: 1, 2: 2, 3: 4, 4: 5, 8: 14, 16: 28, 32: 57, 64: 120}
    for case in cases:
        case_id = case["id"]
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if not isinstance(values, list):
            errors.append(f"input_values must be a JSON array: {case_id}")
            continue
        primary = primary_result(values, input_is_null=input_is_null, input_length=input_length)
        independent = independent_result(values, input_is_null=input_is_null, input_length=input_length)
        if primary != independent:
            errors.append(f"A005658 references disagree: {case_id}")
        if case.get("expected_result") != primary:
            errors.append(f"A005658 expected_result mismatch: {case_id}")
        if primary >= 0 and primary > MAX_RESULT:
            errors.append(f"A005658 result exceeds the published-prefix bound: {case_id}")
        if primary == INVALID_RESULT and case.get("input_is_null", False) and input_length != 0:
            errors.append(f"A005658 null-input fixture framing mismatch: {case_id}")
        if values and values[0] in published and len(values) == 1:
            if primary != published[values[0]]:
                errors.append(f"A005658 published prefix checkpoint mismatch: {case_id}")
    return errors


def main() -> int:
    errors = verify_workload()
    if errors:
        raise SystemExit("\n".join(errors))
    return 0
