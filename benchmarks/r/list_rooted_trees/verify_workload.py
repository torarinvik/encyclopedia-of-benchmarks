"""Static inventory and fixture checks for the rooted-tree package."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/list_rooted_trees"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}
SYMBOL = "list_rooted_trees"


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "r" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_input_length") != 1
            or workload.get("input", {}).get("maximum_parseable_input_length") != 2
            or workload.get("output", {}).get("maximum_bytes") != 674
            or workload.get("workspace", {}).get("bytes") != 16384
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload identity, ABI bounds, or workspace budget differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if (not isinstance(values, list) or type(expected_result) is not int
                or not isinstance(expected_hex, str)):
            issues.append(f"invalid workload fixture: {case_id}")
            continue
        expected_bytes = bytes.fromhex(expected_hex)
        primary = primary_output(values)
        independent = independent_output(values)
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        if type(output_is_null) is not bool:
            issues.append(f"invalid output-null flag: {case_id}")
            continue
        if primary[0] >= 0 and (output_is_null
                or type(capacity) is int and capacity < primary[0]):
            primary = (-2, b"")
            independent = (-2, b"")
        if (primary != independent or primary[0] != expected_result
                or primary[1] != expected_bytes):
            issues.append(f"fixture/reference mismatch: {case_id}")
    required = {"one-vertex", "three-vertex-chain-and-star", "four-unordered-shapes",
                "above-bound-invalid", "trailing-value-invalid", "short-output-capacity",
                "null-output"}
    if not required <= seen:
        issues.append("missing required cases: " + ", ".join(sorted(required - seen)))
    return issues


static_issues = verify_workload
