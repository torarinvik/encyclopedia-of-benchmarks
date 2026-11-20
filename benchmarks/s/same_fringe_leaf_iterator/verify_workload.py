"""Static workload and reference agreement checks for same-fringe comparison."""

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
    if (workload.get("algorithm") != "same_fringe_leaf_iterator"
            or workload.get("function_symbol") != "same_fringe_leaf_iterator"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("maximum_total_nodes") != primary_oracle.MAX_TOTAL_NODES
            or input_spec.get("node_count_range_per_tree") != [1, primary_oracle.MAX_NODES_PER_TREE]
            or input_spec.get("invalid_input_result") != primary_oracle.INVALID_RESULT):
        issues.append("input bounds differ from the primary reference")
    output_spec = workload.get("output", {})
    if (output_spec.get("valid_result_range") != [0, primary_oracle.MAX_RESULT]
            or output_spec.get("invalid_input_result") != primary_oracle.INVALID_RESULT):
        issues.append("output range differs from the primary reference")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES:
        issues.append("workspace cap differs from the primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["cases must be a list of objects"]
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate fixture ID: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"input framing mismatch: {case_id}")
            continue
        kwargs = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_oracle.expected_result(values, **kwargs) != expected:
            issues.append(f"primary expected result mismatch: {case_id}")
        if independent_oracle.expected_result(values, **kwargs) != expected:
            issues.append(f"independent expected result mismatch: {case_id}")
    required = {
        "single-equal-leaves", "single-unequal-leaves", "equal-fringes-different-shapes",
        "first-leaf-mismatch", "middle-leaf-mismatch", "last-leaf-mismatch",
        "same-prefix-different-leaf-count", "maximum-node-tables-equal-fringes",
        "signed-i64-leaf-labels", "empty-null-input", "short-header", "trailing-word",
        "invalid-node-count", "unary-node-invalid", "duplicate-child-invalid",
        "unreachable-record-invalid", "cycle-invalid", "out-of-range-child-invalid",
    }
    if seen != required:
        issues.append("fixture IDs differ from the reviewed inventory")
    return issues
