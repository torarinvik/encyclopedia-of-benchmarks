"""Static workload/reference checks; does not run compiled benchmark programs."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_result as independent_expected
from .primary_oracle import expected_result as primary_expected

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "triangulation_stochastic_visibility_walk":
        issues.append("workload algorithm does not match the package")
    if workload.get("function_symbol") != "triangulation_stochastic_visibility_walk":
        issues.append("workload function symbol does not match the package")
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
            issues.append("workload fixture IDs must be unique strings")
            continue
        identifiers.add(case_id)
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture {case_id} has inconsistent input framing")
            continue
        primary = primary_expected(values)
        independent = independent_expected(values)
        if primary != independent:
            issues.append(f"fixture {case_id} differs between its independent references")
        if case.get("expected_result") != primary:
            issues.append(f"fixture {case_id} has an incorrect documented expected result")
    required_cases = {
        "initial-face-is-target", "two-successor-choice-first",
        "two-successor-choice-second-then-single-successor",
        "choice-tape-exhausted-at-branch", "step-cap-before-branch-choice",
        "maximum-valid-frame-and-ignored-extra-choice-bits", "trailing-word",
        "choice-symbol-out-of-range", "query-on-hull-boundary",
    }
    if identifiers != required_cases:
        issues.append("workload does not contain the complete named fixture set")
    return issues
