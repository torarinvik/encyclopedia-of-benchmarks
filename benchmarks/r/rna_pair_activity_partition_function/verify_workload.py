"""Statically reconcile bounded fixtures against both interval references."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "empty-sequence",
    "single-unpaired-base",
    "one-pair-activity-three",
    "three-base-weighted-choices",
    "all-unit-activities-four-bases",
    "nonuniform-activities-four-bases",
    "all-unit-activities-six-bases",
    "all-triple-activities-eight-bases",
    "maximum-valid-length-with-disabled-pairs",
    "negative-length",
    "length-over-profile",
    "truncated-pair-list",
    "trailing-value",
    "negative-activity",
    "activity-over-profile",
    "empty-frame",
    "null-input",
}


def static_issues(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    if (workload.get("algorithm") != "rna_pair_activity_partition_function"
            or workload.get("function_symbol") != "rna_pair_activity_partition_function"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    input_spec = workload.get("input")
    if (not isinstance(input_spec, dict)
            or input_spec.get("maximum_sequence_length") != 16
            or input_spec.get("maximum_valid_input_length") != 121
            or input_spec.get("maximum_parseable_input_length") != 122
            or input_spec.get("activity_range") != [0, 3]):
        issues.append("input bounds differ")
    workspace = workload.get("workspace")
    if not isinstance(workspace, dict) or workspace.get("bytes") != 2048:
        issues.append("workspace bound differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or length != len(values) or type(input_is_null) is not bool
                or type(expected) is not int):
            issues.append(f"invalid case fields: {case_id}")
            continue
        primary = primary_result(values, input_is_null, length)
        independent = independent_result(values, input_is_null, length)
        if primary != expected:
            issues.append(f"primary reference differs from expected result: {case_id}")
        if independent != expected:
            issues.append(f"independent reference differs from expected result: {case_id}")
        if primary != independent:
            issues.append(f"references disagree: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("workload case inventory differs")
    return issues
