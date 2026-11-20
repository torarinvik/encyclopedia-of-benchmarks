"""Static fixture/reference review; never launches compiled benchmark programs."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "convex_polygon_minimum_weight_triangulation"


def workload_issues() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI does not match the package")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length")
            != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("input", {}).get("kind") != "signed_64_bit_integer_array"
            or workload.get("input", {}).get("exact_length") != "1+n*(n-3)/2"
            or workload.get("output", {}).get("result_range") != [0, 7000]
            or workload.get("source", {}).get("url")
            != "https://doi.org/10.1007/978-1-4939-2864-4_715"
            or workload.get("source", {}).get("primary_method_url")
            != "https://doi.org/10.1016/S0167-5060(08)70044-X"):
        issues.append("workload bounds differ from the primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append("case IDs must be unique strings")
            continue
        seen.add(case_id)
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"case {case_id} has inconsistent input framing")
            continue
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_expected(values, **options)
        independent = independent_expected(values, **options)
        if primary != independent:
            issues.append(f"case {case_id} differs between the two references")
        if case.get("expected_result") != primary:
            issues.append(f"case {case_id} has an incorrect expected result")
    if "maximum-vertex-count-zero-cost" not in seen:
        issues.append("workload omits the maximum-size valid frame")
    if "maximum-score-all-diagonals-equal" not in seen:
        issues.append("workload omits the maximum-score fixture")
    if "maximum-parseable-trailing-word" not in seen:
        issues.append("workload omits the maximum parseable malformed frame")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("; ".join(issues))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    return len(workload["cases"])


def static_issues() -> list[str]:
    return workload_issues()
