"""Fixture/reference reconciliation; native ports are not executed."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent
SYMBOL = "gaussian_prime_classifier"


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("maximum_norm") != primary_oracle.MAX_NORM
            or workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES):
        issues.append("workload bounds differ from the primary reference")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture must have a string id")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        primary = primary_oracle.expected_result(values, input_is_null, length)
        independent = independent_oracle.expected_result(values, input_is_null, length)
        if primary != independent:
            issues.append(f"references disagree for {case_id}")
        if primary != expected:
            issues.append(f"pinned result differs for {case_id}")
    return issues


def verify_workload() -> None:
    problems = workload_issues()
    if problems:
        raise ValueError("\n".join(problems))
