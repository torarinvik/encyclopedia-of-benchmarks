"""Static workload/reference agreement source; it is not auto-run."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_expected_result
from .primary_oracle import expected_result as primary_expected_result

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        for label, reference in (("primary", primary_expected_result),
                                 ("independent", independent_expected_result)):
            actual = reference(case["input_values"], **options)
            if actual != case["expected_result"]:
                issues.append(f"{case['id']}: {label} returned {actual!r}")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise SystemExit("\n".join(problems))
