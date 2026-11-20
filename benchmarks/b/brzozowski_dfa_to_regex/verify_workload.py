"""Static fixture/reference reconciliation; this module runs no native port."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import language_equivalent
from .primary_oracle import expected_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid workload JSON: {error}"]
    issues: list[str] = []
    if workload.get("algorithm") != "brzozowski_dfa_to_regex":
        issues.append("workload algorithm identity differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            issues.append("malformed fixture record")
            continue
        values = case["input_values"]
        options = {
            "capacity": case.get("output_capacity", 270),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        actual = expected_output(values, **options)
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        if actual != expected:
            issues.append(f"fixture differs from primary reference: {case.get('id')}")
        expected_text = case.get("expected_output")
        if expected_text is not None:
            if expected_text.encode("ascii") != expected[1]:
                issues.append(f"expected text/hex differ: {case.get('id')}")
        if actual[0] >= 0 and not language_equivalent(
                values, actual[1], input_length=options["input_length"]):
            issues.append(f"regex language differs from DFA: {case.get('id')}")
        if actual[0] < 0 and actual[1] != b"":
            issues.append(f"error case writes bytes: {case.get('id')}")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
