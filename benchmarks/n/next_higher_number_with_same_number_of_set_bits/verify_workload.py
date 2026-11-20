"""Static comparison of workload fixtures with both separate references."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        value = case["input_value"]
        expected = case["expected_result"]
        for label, reference in (("primary", primary_result), ("independent", independent_result)):
            actual = reference(value)
            if actual != expected:
                issues.append(f"{case['id']}: {label} expected {expected}, got {actual}")
    return issues
