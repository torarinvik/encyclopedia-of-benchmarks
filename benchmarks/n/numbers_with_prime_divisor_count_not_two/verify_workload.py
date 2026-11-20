"""Static workload/reference agreement source; this file is not auto-run."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import expected_output as primary_expected_output

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        for label, reference in (("primary", primary_expected_output),
                                 ("independent", independent_expected_output)):
            actual = reference(case["input_values"], **options)
            if actual != expected:
                issues.append(f"{case['id']}: {label} returned {actual!r}")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise SystemExit("\n".join(problems))
