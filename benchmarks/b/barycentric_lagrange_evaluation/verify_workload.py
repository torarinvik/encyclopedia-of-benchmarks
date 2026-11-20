"""Static workload/reference reconciliation API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID,
        WORKSPACE_BYTES as INDEPENDENT_WORKSPACE,
        expected_result as independent_result,
    )
    from .primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MODULUS,
        WORKSPACE_BYTES,
        expected_result,
    )
except ImportError:
    from independent_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID,
        WORKSPACE_BYTES as INDEPENDENT_WORKSPACE,
        expected_result as independent_result,
    )
    from primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MODULUS,
        WORKSPACE_BYTES,
        expected_result,
    )

PACKAGE = Path(__file__).resolve().parent
SOURCE_URL = "https://dlmf.nist.gov/3.3.i#E1"


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "barycentric_lagrange_evaluation"
            or workload.get("function_symbol") != "barycentric_lagrange_evaluation"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity, ABI, or DLMF source differs")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("node_count_range") != [1, 8]
            or workload.get("output", {}).get("result_range") != [0, MODULUS - 1]
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or (INDEPENDENT_MAX_VALID, INDEPENDENT_MAX_INPUT, INDEPENDENT_WORKSPACE)
            != (MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH, 512)):
        issues.append("workload bounds or reference workspace differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"fixture input is not a list: {case_id}")
            continue
        input_is_null = case.get("input_is_null", False)
        if type(input_is_null) is not bool:
            issues.append(f"fixture null-input flag is not boolean: {case_id}")
            continue
        input_length = case.get("input_length")
        if type(input_length) is not int:
            issues.append(f"fixture input length is missing or invalid: {case_id}")
            continue
        if (input_is_null and (values or input_length != 0)
                or not input_is_null and input_length != len(values)):
            issues.append(f"fixture frame metadata differs: {case_id}")
        try:
            primary = expected_result(values, input_is_null, input_length)
            independent = independent_result(values, input_is_null, input_length)
        except (ArithmeticError, OverflowError, TypeError, ValueError, StopIteration) as error:
            issues.append(f"oracle could not classify {case_id}: {error}")
            continue
        pinned = case.get("expected_result")
        if primary != pinned:
            issues.append(f"fixture differs from barycentric reference: {case_id}")
        if independent != primary:
            issues.append(f"Vandermonde oracle disagrees: {case_id}")
    if not any(isinstance(case, dict) and case.get("input_length") == MAX_VALID_INPUT_LENGTH
               and case.get("expected_result") == 7 for case in cases):
        issues.append("maximum valid node-count fixture is missing")
    if not any(isinstance(case, dict) and case.get("input_length") == MAX_PARSEABLE_INPUT_LENGTH
               and case.get("expected_result") == -1 for case in cases):
        issues.append("maximum parseable trailing-frame fixture is missing")
    if not any(isinstance(case, dict) and case.get("id") == "query-at-node"
               and case.get("expected_result") >= 0 for case in cases):
        issues.append("node-hit special case fixture is missing")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    return len(workload["cases"])


if __name__ == "__main__":
    print(f"{verify_workload()} fixtures reconciled")
