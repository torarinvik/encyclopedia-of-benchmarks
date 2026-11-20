"""Compare pinned fixtures with the primary and exact-system reference."""

from __future__ import annotations

import json
import math
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    absolute = data["output"]["absolute_tolerance"]
    relative = data["output"]["relative_tolerance"]
    issues: list[str] = []
    for case in data["cases"]:
        values = case["input_values"]
        expected_status = case["expected_result"]
        expected_values = tuple(case["expected_output"])
        for label, reference in (("primary", primary_output),
                                 ("independent", independent_output)):
            result, output = reference(values, input_length=case["input_length"])
            if result != expected_status or len(output) != len(expected_values):
                issues.append(f"{case['id']}: {label} status/output length differs")
                continue
            if any(abs(actual - expected) > absolute + relative * abs(expected)
                   for actual, expected in zip(output, expected_values)):
                issues.append(f"{case['id']}: {label} output differs from fixture")
    for case in data.get("abi_cases", []):
        values = case["input_values"]
        expected_status = case["expected_result"]
        expected_values = tuple(case["expected_output"])
        for label, reference in (("primary", primary_output),
                                 ("independent", independent_output)):
            result, output = reference(
                values, case.get("output_capacity", 1), case.get("output_is_null", False),
                case.get("input_is_null", False), case.get("input_length"))
            if result != expected_status or output != expected_values:
                issues.append(f"{case['id']}: {label} ABI status/output differs")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
