"""Fixture/oracle agreement checker; intentionally not run for this draft."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import expected_output as primary_expected_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        return ["workload has no cases"]
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"invalid or duplicate case id: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        if not isinstance(values, list) or type(length) is not int or type(expected) is not int:
            issues.append(f"malformed fixture fields: {case_id}")
            continue
        if length != len(values):
            issues.append(f"declared input length mismatch: {case_id}")
            continue
        primary = primary_expected_output(values, is_null, length)
        independent = independent_expected_output(values, is_null, length)
        if primary != expected or independent != expected:
            issues.append(
                f"oracle/fixture mismatch for {case_id}: expected={expected}, "
                f"primary={primary}, independent={independent}"
            )
    return issues
