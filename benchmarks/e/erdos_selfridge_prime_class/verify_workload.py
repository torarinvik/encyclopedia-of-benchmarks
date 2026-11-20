"""Metadata-only fixture/oracle reconciliation helper; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

WORKLOAD = Path(__file__).with_name("workload.json")


def static_issues() -> list[str]:
    document = json.loads(WORKLOAD.read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in document.get("cases", []):
        values = case.get("input_values", [])
        is_null = case.get("input_is_null", False)
        length = case.get("input_length", len(values))
        primary = primary_oracle.expected_result(values, is_null, length)
        independent = independent_oracle.expected_result(values, is_null, length)
        if primary != independent:
            issues.append(f"{case.get('id')}: references disagree ({primary} != {independent})")
        if primary != case.get("expected_result"):
            issues.append(f"{case.get('id')}: pinned result differs from references")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))

