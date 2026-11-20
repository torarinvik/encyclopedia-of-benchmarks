"""Static fixture reconciliation against both mathematical references."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent


def static_issues() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in workload.get("cases", []):
        actual_length = case.get("input_length")
        values = case.get("input_values")
        if not isinstance(values, list) or type(actual_length) is not int:
            issues.append(f"{case.get('id')}: malformed fixture encoding")
            continue
        primary = primary_oracle.expected_result(
            values, case.get("input_is_null", False), actual_length
        )
        independent = independent_oracle.expected_result(
            values, case.get("input_is_null", False), actual_length
        )
        if primary != independent:
            issues.append(f"{case.get('id')}: references disagree: {primary} != {independent}")
        if case.get("expected_result") != primary:
            issues.append(f"{case.get('id')}: pinned result differs from reference {primary}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
