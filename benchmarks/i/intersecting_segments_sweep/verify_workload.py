"""Static workload/reference checks; never launches compiled benchmark ports."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "empty-set", "disjoint-overlapping-x-ranges", "disjoint-x-ranges",
    "proper-crossing", "endpoint-on-segment", "collinear-overlap",
    "maximum-size-disjoint-set", "negative-segment-count", "vertical-segment",
    "duplicate-endpoint-x", "coordinate-out-of-range", "trailing-word",
    "truncated-frame", "null-input",
}


def verify_workload() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "intersecting_segments_sweep":
        issues.append("workload algorithm does not match the package")
    if workload.get("function_symbol") != "intersecting_segments_sweep":
        issues.append("workload symbol does not match the package")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI is not i64_array_scalar")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixture list"]
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object fixture")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        if not isinstance(case_id, str) or case_id in identifiers:
            issues.append("fixture IDs must be unique strings")
            continue
        identifiers.add(case_id)
        input_length = case.get("input_length")
        if (not isinstance(values, list) or type(input_length) is not int
                or input_length < 0 or input_length != len(values)):
            issues.append(f"fixture {case_id} has inconsistent framing")
            continue
        input_is_null = case.get("input_is_null", False)
        if type(input_is_null) is not bool:
            issues.append(f"fixture {case_id} has a non-boolean null flag")
            continue
        options = {"input_length": input_length, "input_is_null": input_is_null}
        primary = primary_result(values, **options)
        independent = independent_result(values, **options)
        if primary != independent:
            issues.append(f"fixture {case_id} differs between sweep and pairwise references")
        if case.get("expected_result") != primary:
            issues.append(f"fixture {case_id} has an incorrect documented scalar result")
    if identifiers != REQUIRED_CASES:
        issues.append("workload does not include the complete named fixture set")
    return issues
