"""Static fixture/reference consistency for Hofstadter Q."""
from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary

PACKAGE = Path(__file__).resolve().parent


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if (not isinstance(workload, dict)
            or workload.get("algorithm") != "hofstadter_q_sequence"
            or workload.get("function_symbol") != "hofstadter_q_sequence"
            or workload.get("abi") != "i64_array_scalar"):
        return ["workload metadata does not match the package contract"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        input_length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        input_is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(case_id, str) or case_id in seen or not isinstance(values, list)
                or type(input_length) is not int or type(input_is_null) is not bool
                or type(expected) is not int):
            issues.append(f"invalid or duplicate fixture fields: {case_id}")
            continue
        seen.add(case_id)
        args = {"input_length": input_length, "input_is_null": input_is_null}
        if primary(values, **args) != expected:
            issues.append(f"primary reference disagrees with fixture: {case_id}")
        if independent(values, **args) != expected:
            issues.append(f"independent reference disagrees with fixture: {case_id}")
    return issues
