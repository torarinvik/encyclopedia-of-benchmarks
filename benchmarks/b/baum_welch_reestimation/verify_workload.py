"""Compare Baum–Welch fixtures with dynamic-programming and path references."""

from __future__ import annotations

import json
import math
from pathlib import Path

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import (
    OUTPUT_ABSOLUTE_TOLERANCE,
    OUTPUT_RELATIVE_TOLERANCE,
    expected_output as primary_expected_output,
)

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
            "output_is_null": case.get("output_is_null", False),
            "output_capacity": case.get("output_capacity"),
        }
        expected_result = case["expected_result"]
        expected = case["expected_output"]
        for label, reference in (("primary", primary_expected_output),
                                 ("independent", independent_expected_output)):
            result, output = reference(case["input_values"], **options)
            if result != expected_result:
                issues.append(f"{case['id']}: {label} result disagrees with fixture")
                continue
            if len(output) != len(expected) or any(
                    not math.isclose(actual, wanted,
                                     rel_tol=OUTPUT_RELATIVE_TOLERANCE,
                                     abs_tol=OUTPUT_ABSOLUTE_TOLERANCE)
                    for actual, wanted in zip(output, expected)):
                issues.append(f"{case['id']}: {label} output disagrees with fixture")
    return issues


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
