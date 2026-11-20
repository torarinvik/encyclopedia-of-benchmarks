"""Source-only workload/reference reconciler. It is intentionally not run here."""

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
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            issues.append(f"invalid or duplicate case id: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or length != len(values):
            issues.append(f"{case_id}: input length does not match values")
            continue
        argument = None if case.get("input_is_null") else values
        expected = case.get("expected_result")
        first = primary_expected(argument)
        second = independent_expected(argument)
        if first != expected:
            issues.append(f"{case_id}: primary result {first} differs from pinned {expected}")
        if second != expected:
            issues.append(f"{case_id}: independent result {second} differs from pinned {expected}")
        if first != second:
            issues.append(f"{case_id}: references disagree ({first} vs {second})")
    return issues


def verify() -> list[str]:
    return workload_issues()
