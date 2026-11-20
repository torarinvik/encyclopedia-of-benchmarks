"""Static workload/reference consistency review for long-chain DP."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import MAX_N, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output  # type: ignore[no-redef]
    from primary_oracle import MAX_N, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES
    from primary_oracle import expected_output as primary_output  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "long_chain_dominant_depth_index"
SOURCE_PATHS = (
    "c/l/long_chain_dominant_depth_index.c",
    "c3/l/long_chain_dominant_depth_index.c3",
    "cpp/l/long_chain_dominant_depth_index.cpp",
    "elisa/l/long_chain_dominant_depth_index.elisa",
    "mojo/l/long_chain_dominant_depth_index.mojo",
    "nim/l/long_chain_dominant_depth_index.nim",
    "odin/l/long_chain_dominant_depth_index.odin",
    "rust/l/long_chain_dominant_depth_index.rs",
    "v/l/long_chain_dominant_depth_index.v",
    "zig/l/long_chain_dominant_depth_index.zig",
)


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
                 "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for source in SOURCE_PATHS:
        path = ROOT / source
        if not path.is_file():
            issues.append(f"missing source: {source}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {source}")
    inventory_path = PACKAGE / "INVENTORY.md"
    if inventory_path.is_file():
        inventory = inventory_path.read_text(encoding="utf-8")
        for source in SOURCE_PATHS:
            if source not in inventory:
                issues.append(f"inventory omits {source}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_input_length") != MAX_N
            or workload.get("input", {}).get("maximum_parseable_input_length") != MAX_N + 1
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("output", {}).get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload identity, ABI limits, or resource bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload fixture")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"missing input values: {case_id}")
            continue
        input_length = case.get("input_length")
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        result = primary_output(values, input_is_null, input_length, capacity, output_is_null)
        independent = independent_output(values, input_is_null, input_length, capacity, output_is_null)
        expected = case.get("expected_result")
        expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        if result != independent or result != (expected, expected_bytes):
            issues.append(f"fixture/reference mismatch: {case_id}")
    required_cases = {"single_vertex", "three_vertex_path", "four_vertex_star",
                      "balanced_binary_tree", "shallowest_depth_wins_tie",
                      "invalid_parent_not_earlier", "null_input",
                      "short_output_capacity", "null_output"}
    if not required_cases <= seen:
        issues.append("missing required edge cases: " + ", ".join(sorted(required_cases - seen)))
    return issues
