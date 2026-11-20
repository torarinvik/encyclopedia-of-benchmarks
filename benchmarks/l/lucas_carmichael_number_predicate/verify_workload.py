"""Metadata-only fixture/reference consistency helper; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALUE,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_result as primary,
)

PACKAGE = Path(__file__).resolve().parent
EXPECTED_TRUE = {399, 935, 2015, 2915, 4991}


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    if (workload.get("algorithm") != "lucas_carmichael_number_predicate"
            or workload.get("function_symbol") != "lucas_carmichael_number_predicate"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("n_range") != [1, MAX_VALUE]
            or workload.get("input", {}).get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload identity, bounds, ABI, or workspace differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    true_values: set[int] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        length = case.get("input_length")
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(length) is not int or type(expected) is not int
                or (input_is_null and (values or length != 0))
                or (not input_is_null and length != len(values))):
            issues.append(f"invalid fields in case: {case_id}")
            continue
        if (primary(values, input_is_null=input_is_null, input_length=length) != expected
                or independent(values, input_is_null=input_is_null, input_length=length) != expected):
            issues.append(f"oracle mismatch: {case_id}")
        if len(values) == 1 and values[0] in EXPECTED_TRUE and expected == 1:
            true_values.add(values[0])
    if true_values != EXPECTED_TRUE:
        issues.append("known Lucas-Carmichael fixture set is incomplete or changed")
    if not {"trailing-word", "null-input", "profile-maximum"} <= seen:
        issues.append("required framing and bound fixtures are missing")
    return issues


static_issues = verify_workload
