"""Compare workload fixtures with both string-search references."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import expected_output as primary_expected_output

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
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        for label, reference in (("primary", primary_expected_output),
                                 ("independent", independent_expected_output)):
            if reference(case["input_values"], **options) != expected:
                issues.append(f"{case['id']}: {label} reference disagrees with fixture")
    return issues


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
