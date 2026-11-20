"""Static workload-to-oracle reconciliation; no native code is executed."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid workload JSON: {error}"]
    issues: list[str] = []
    if workload.get("algorithm") != "snake_case_to_camel_pascal_case":
        issues.append("workload algorithm identity differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixture cases"]
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            issues.append("malformed fixture record")
            continue
        options = {
            "capacity": case.get("output_capacity", 256),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        values = case["input_values"]
        primary = primary_output(values, **options)
        independent = independent_output(values, **options)
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        if primary != independent:
            issues.append(f"reference disagreement: {case.get('id')}")
        if primary != expected:
            issues.append(f"fixture mismatch: {case.get('id')}")
        expected_text = case.get("expected_output")
        if expected_text is not None and expected_text.encode("ascii") != primary[1]:
            issues.append(f"fixture text differs from bytes: {case.get('id')}")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
