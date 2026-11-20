"""Static workload cross-check for the Vizing edge-coloring package."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "misra_gries_edge_coloring"
            or workload.get("function_symbol") != "misra_gries_edge_coloring"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    contract = workload.get("input", {})
    if (contract.get("vertices_range") != [1, primary_oracle.MAX_VERTICES]
            or contract.get("edges_range") != [0, primary_oracle.MAX_EDGES]
            or contract.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input bounds differ from primary reference")
    if workload.get("output", {}).get("valid_result_range") != [0, primary_oracle.MAX_RESULT]:
        issues.append("output bound differs from primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["cases must be objects"]
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate case ID: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"bad input frame: {case_id}")
            continue
        is_null = case.get("input_is_null", False)
        length = case["input_length"]
        expected = case.get("expected_result")
        actual = primary_oracle.expected_result(values, is_null, length)
        if actual != expected:
            issues.append(f"primary expected result differs: {case_id}")
        if not independent_oracle.verify_result(values, expected, is_null, length):
            issues.append(f"independent certificate rejected: {case_id}")
    required = {
        "empty-graph", "single-edge", "two-edge-path", "triangle-three-colors",
        "fan-kempe-inversion", "maximum-valid-k4-frame", "maximum-degree-star",
        "self-loop-invalid", "duplicate-edge-invalid", "endpoint-out-of-range-invalid",
        "truncated-frame-invalid", "trailing-word-invalid",
        "maximum-parseable-trailing-invalid", "null-input", "i64-min-invalid",
        "i64-max-invalid",
    }
    if seen != required:
        issues.append("fixture IDs differ from required inventory")
    return issues
