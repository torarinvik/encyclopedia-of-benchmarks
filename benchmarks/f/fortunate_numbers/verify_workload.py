"""Static workload/reference consistency helper; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES,
        expected_result,
    )
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import (
        MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES,
        expected_result,
    )

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (data.get("algorithm") != "fortunate_numbers"
            or data.get("function_symbol") != "fortunate_numbers"
            or data.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if (data.get("input", {}).get("n_range") != [1, MAX_N]
            or data.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or data.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or data.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload input or workspace bounds differ")
    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        name = case["id"]
        if name in seen:
            issues.append(f"duplicate fixture id: {name}")
            continue
        seen.add(name)
        values = case.get("input_values")
        if not isinstance(values, list) or type(case.get("input_length")) is not int:
            issues.append(f"invalid frame: {name}")
            continue
        if not case.get("input_is_null", False) and case["input_length"] != len(values):
            issues.append(f"frame length mismatch: {name}")
        kwargs = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        primary = expected_result(values, **kwargs)
        independent = independent_result(values, **kwargs)
        if primary != case.get("expected_result") or independent != case.get("expected_result"):
            issues.append(f"reference result differs: {name}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
