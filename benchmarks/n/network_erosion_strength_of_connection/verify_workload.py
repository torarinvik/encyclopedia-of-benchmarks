"""Static workload/reference checks; never launches compiled benchmark ports."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_output as independent_output
from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_output as primary_output
from .primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "complete-three-vertex-normalizes-to-one", "single-chain-three-vertices",
    "lexicographic-tie-between-shortest-paths", "unassigned-vertex-contributes-zero",
    "endpoint-retains-initial-direct-distance", "disconnected-endpoints-zero-score",
    "maximum-complete-directed-graph", "duplicate-arc", "out-of-range-endpoint",
    "same-source-and-target-excluded", "trailing-word", "short-output-capacity",
    "null-output", "null-input",
}


def verify_workload() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "network_erosion_strength_of_connection":
        issues.append("workload algorithm does not match the package")
    if workload.get("function_symbol") != "network_erosion_strength_of_connection":
        issues.append("workload function symbol does not match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI is not i64_array_bytes_output")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixture list"]
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object fixture")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        if not isinstance(case_id, str) or case_id in identifiers:
            issues.append("fixture IDs must be unique strings")
            continue
        identifiers.add(case_id)
        input_length = case.get("input_length")
        if (not isinstance(values, list) or type(input_length) is not int
                or input_length < 0 or input_length != len(values)):
            issues.append(f"fixture {case_id} has inconsistent framing")
            continue
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity", 16)
        if type(input_is_null) is not bool or type(output_is_null) is not bool:
            issues.append(f"fixture {case_id} has a non-boolean null flag")
            continue
        if type(capacity) is not int or capacity < 0:
            issues.append(f"fixture {case_id} has an invalid output capacity")
            continue
        options = {
            "input_length": case["input_length"],
            "input_is_null": input_is_null,
            "output_capacity": capacity,
            "output_is_null": output_is_null,
        }
        result = primary_result(values, **options)
        other_result = independent_result(values, **options)
        output = primary_output(values, **options)
        other_output = independent_output(values, **options)
        if result != other_result or output != other_output:
            issues.append(f"fixture {case_id} differs between the BFS and exhaustive-path references")
        if case.get("expected_result") != result:
            issues.append(f"fixture {case_id} has an incorrect documented result")
        if case.get("expected_output_hex") != output.hex():
            issues.append(f"fixture {case_id} has an incorrect documented output")
    if identifiers != REQUIRED_CASES:
        issues.append("workload does not include the complete named fixture set")
    return issues
