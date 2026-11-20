"""Static fixture/reference cross-checks; does not launch language programs."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_output as independent_expected
from .primary_oracle import expected_output as primary_expected

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "two-independent-first-choices", "one-rank-one-edge-one-rank-two-edge",
    "rank-one-priority-through-rank-four", "rank-gap-keeps-lower-rank-edge",
    "tied-rank-one-complete-market", "maximum-four-by-four-frame",
    "duplicate-edge-invalid", "applicant-without-listed-post-invalid",
    "rank-outside-profile-invalid", "maximum-parseable-trailing-word",
    "null-input", "short-output-capacity", "null-output",
}


def workload_issues() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "rank_maximal_matching_irving":
        issues.append("workload algorithm does not match the package")
    if workload.get("function_symbol") != "rank_maximal_matching_irving":
        issues.append("workload function symbol does not match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI is not i64_array_bytes_output")
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
        common = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_expected(values, **common)
        independent = independent_expected(values, **common)
        if primary != independent:
            issues.append(f"fixture {case_id} differs between phase and exhaustive references")
        result, payload = primary
        if case.get("expected_result") != result:
            issues.append(f"fixture {case_id} has an incorrect documented result")
        if case.get("expected_output_hex", "") != payload.hex():
            issues.append(f"fixture {case_id} has an incorrect documented byte payload")
    if identifiers != REQUIRED_CASES:
        issues.append("workload does not contain the complete named fixture set")
    return issues


def verify_workload() -> list[str]:
    return workload_issues()
