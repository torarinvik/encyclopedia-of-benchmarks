"""Source-level review of package fixtures against both mathematical references."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    seen: set[str] = set()
    for case in data.get("cases", []):
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"fixture ID is missing or duplicated: {case_id!r}")
            continue
        seen.add(case_id)
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_output(case.get("input_values"), **options) != expected:
            issues.append(f"primary fixture mismatch: {case_id}")
        if independent_output(case.get("input_values"), **options) != expected:
            issues.append(f"independent fixture mismatch: {case_id}")
    if "maximum-valid-frame" not in seen:
        issues.append("maximum-valid-frame fixture is missing")
    if "maximum-parseable-trailing-word" not in seen:
        issues.append("maximum-parseable-trailing-word fixture is missing")
    return issues
