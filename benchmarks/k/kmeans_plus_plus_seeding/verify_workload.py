"""Optional consistency check for deterministic draw fixtures and references."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in workload["cases"]:
        values = case.get("input_values", [])
        arguments = (
            values,
            case.get("input_is_null", False),
            case.get("input_length", len(values)),
            case.get("output_is_null", False),
            case.get("output_capacity"),
        )
        expected_result = case["expected_result"]
        expected_hex = case.get("expected_output_hex", "")
        for label, reference in (("primary", primary_output), ("independent", independent_output)):
            result, output = reference(*arguments)
            if result != expected_result:
                issues.append(f"{case['id']}: {label} result {result} != {expected_result}")
            if output.hex() != expected_hex:
                issues.append(f"{case['id']}: {label} bytes differ from fixture")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise SystemExit("\n".join(problems))
