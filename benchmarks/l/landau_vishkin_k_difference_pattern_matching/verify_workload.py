"""Static fixture/reference reconciliation; this module does not launch ports."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_output as independent_expected
from .primary_oracle import expected_output as primary_expected

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "exact-matches-at-two-endpoints",
    "one-substitution-in-full-pattern",
    "one-text-insertion",
    "one-pattern-deletion",
    "trailing-text-insertion-is-an-endpoint-match",
    "overlapping-zero-error-matches",
    "zero-error-no-match",
    "empty-text",
    "maximum-input-and-output",
    "short-output-capacity",
    "null-output",
    "null-input",
    "trailing-word-invalid",
    "symbol-outside-alphabet",
    "error-budget-must-be-smaller-than-pattern",
}


def workload_issues(workload: dict | None = None) -> list[str]:
    issues = static_issues()
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "landau_vishkin_k_difference_pattern_matching":
        issues.append("workload algorithm differs")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixtures"]
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
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture {case_id} has inconsistent input framing")
            continue
        call = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_expected(values, **call)
        independent = independent_expected(values, **call)
        if primary != independent:
            issues.append(f"fixture {case_id} differs between the two references")
        result, payload = primary
        if case.get("expected_result") != result:
            issues.append(f"fixture {case_id} has an incorrect result")
        if case.get("expected_output_hex", "") != payload.hex():
            issues.append(f"fixture {case_id} has an incorrect output payload")
    if identifiers != REQUIRED_CASES:
        issues.append("workload fixture set differs from the required cases")
    return issues


def verify_workload(workload: dict | None = None) -> list[str]:
    return workload_issues(workload)
