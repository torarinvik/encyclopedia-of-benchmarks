"""Static workload/reference reconciler; intentionally not run during authoring."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import expected_result as primary_expected

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "zwick_deterministic_bridging_set":
        issues.append("workload algorithm identifier differs")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI differs")
    if workload.get("input", {}).get("maximum_valid_length") != 130:
        issues.append("maximum valid input length differs from the contract")
    if workload.get("input", {}).get("maximum_parseable_length") != 131:
        issues.append("maximum parseable input length differs from the contract")
    if workload.get("workspace", {}).get("bytes") != 4096:
        issues.append("workspace bound differs from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id") if isinstance(case, dict) else None
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            issues.append(f"invalid or duplicate case id: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or length != len(values):
            issues.append(f"{case_id}: input length differs from values")
            continue
        argument = None if case.get("input_is_null") else values
        options = {"input_is_null": bool(case.get("input_is_null")),
                   "input_length": length}
        primary = primary_expected(argument, **options)
        independent = independent_expected(argument, **options)
        pinned = case.get("expected_result")
        if primary != pinned:
            issues.append(f"{case_id}: primary {primary} differs from pinned {pinned}")
        if independent != pinned:
            issues.append(f"{case_id}: independent {independent} differs from pinned {pinned}")
        if primary != independent:
            issues.append(f"{case_id}: references disagree ({primary} vs {independent})")
    return issues


def verify() -> list[str]:
    return workload_issues()
