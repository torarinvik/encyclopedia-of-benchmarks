"""Static workload/reference reconciliation API; intentionally not run here."""

from __future__ import annotations

import json
import math
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ABS_TOL = 1e-12
REL_TOL = 1e-12


def _same_outputs(left: list[float], right: list[float]) -> bool:
    return len(left) == len(right) and all(
        math.isclose(a, b, rel_tol=REL_TOL, abs_tol=ABS_TOL)
        for a, b in zip(left, right)
    )


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "de_boor_bspline_curve_evaluation"
            or workload.get("function_symbol") != "de_boor_bspline_curve_evaluation"
            or workload.get("abi") != "float64_slice_io"):
        issues.append("workload identity or ABI differs")
    if (workload.get("input", {}).get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != 1
            or workload.get("output", {}).get("maximum_bytes") != 8
            or workload.get("output", {}).get("absolute_tolerance") != ABS_TOL
            or workload.get("output", {}).get("relative_tolerance") != REL_TOL
            or workload.get("measurement", {}).get("absolute_tolerance") != ABS_TOL
            or workload.get("measurement", {}).get("relative_tolerance") != REL_TOL
            or workload.get("workspace", {}).get("elements") != 1
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload bounds differ from the primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    all_cases = cases + (workload.get("abi_cases") if isinstance(workload.get("abi_cases"), list) else [])
    if len(all_cases) == len(cases):
        issues.append("workload ABI cases are missing")
    for case in all_cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if not isinstance(values, list) or type(length) is not int or type(is_null) is not bool:
            issues.append(f"fixture frame metadata is malformed: {case_id}")
            continue
        if (is_null and (values or length != 0)
                or not is_null and length != len(values)):
            issues.append(f"fixture frame metadata differs: {case_id}")
        capacity = case.get("output_capacity", 1)
        output_is_null = case.get("output_is_null", False)
        if type(capacity) is not int or type(output_is_null) is not bool:
            issues.append(f"fixture output metadata is malformed: {case_id}")
            continue
        kwargs = dict(output_capacity=capacity, output_is_null=output_is_null,
                      input_is_null=is_null, input_length=length)
        try:
            primary_result, primary_values = primary_output(values, **kwargs)
            independent_result, independent_values = independent_output(values, **kwargs)
        except (ArithmeticError, OverflowError, TypeError, ValueError, IndexError) as error:
            issues.append(f"reference could not classify {case_id}: {error}")
            continue
        if primary_result != case.get("expected_result"):
            issues.append(f"pinned result differs from primary reference: {case_id}")
        if primary_result != independent_result or not _same_outputs(primary_values, independent_values):
            issues.append(f"independent basis reference disagrees: {case_id}")
        pinned = case.get("expected_output")
        if pinned is None or not _same_outputs(primary_values, pinned):
            issues.append(f"pinned value differs from primary reference: {case_id}")
    if not any(case.get("input_length") == MAX_VALID_INPUT_LENGTH
               and case.get("expected_result") == 1 for case in cases if isinstance(case, dict)):
        issues.append("maximum valid frame fixture is missing")
    if not any(case.get("input_length") == MAX_PARSEABLE_INPUT_LENGTH
               and case.get("expected_result") == -1 for case in cases if isinstance(case, dict)):
        issues.append("maximum parseable trailing-frame fixture is missing")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    return len(workload["cases"]) + len(workload["abi_cases"])


if __name__ == "__main__":
    print(f"{verify_workload()} fixtures reconciled")
