"""Static workload/reference consistency helper; intentionally not run here."""

from __future__ import annotations

import json
import math
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        ABSOLUTE_TOLERANCE, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_ELEMENTS,
        MAX_VALID_INPUT_LENGTH, RELATIVE_TOLERANCE, WORKSPACE_BYTES,
        expected_output,
    )
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        ABSOLUTE_TOLERANCE, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_ELEMENTS,
        MAX_VALID_INPUT_LENGTH, RELATIVE_TOLERANCE, WORKSPACE_BYTES,
        expected_output,
    )

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (data.get("algorithm") != "rodrigues_arbitrary_axis_rotation"
            or data.get("function_symbol") != "rodrigues_arbitrary_axis_rotation"
            or data.get("abi") != "float64_slice_io"):
        issues.append("workload identity or ABI differs")
    if (data.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or data.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or data.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or data.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or data.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE
            or data.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or data.get("workspace", {}).get("elements") != MAX_OUTPUT_ELEMENTS):
        issues.append("workload bounds or tolerances differ from reference metadata")
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
            issues.append(f"invalid input framing: {name}")
            continue
        if not case.get("input_is_null", False) and case["input_length"] != len(values):
            issues.append(f"input length mismatch: {name}")
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        primary = expected_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        want_result = case.get("expected_result")
        want = case.get("expected_output")
        if primary[0] != want_result or independent[0] != want_result:
            issues.append(f"reference result differs: {name}")
            continue
        if not isinstance(want, list) or len(primary[1]) != len(want) or len(independent[1]) != len(want):
            issues.append(f"reference output length differs: {name}")
            continue
        for actual in (primary[1], independent[1]):
            if any(not math.isclose(float(a), float(b), rel_tol=RELATIVE_TOLERANCE,
                                    abs_tol=ABSOLUTE_TOLERANCE)
                   for a, b in zip(actual, want)):
                issues.append(f"reference output differs: {name}")
                break
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
