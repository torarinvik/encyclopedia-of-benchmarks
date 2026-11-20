"""Static package, metadata, ABI, and independent-reference checks."""

import json
from pathlib import Path

from s.small_to_large_subtree_color_mode_sum.independent_oracle import expected_output as independent
from s.small_to_large_subtree_color_mode_sum.primary_oracle import expected_output as primary

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/small_to_large_subtree_color_mode_sum"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}
SYMBOL = "small_to_large_subtree_color_mode_sum"


def verify_workload(workload=None) -> list[str]:
    issues = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "s" / f"{SYMBOL}.{extension}"
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
    inputs = workload.get("input")
    outputs = workload.get("output")
    workspace = workload.get("workspace")
    measurement = workload.get("measurement")
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_length") != 128
            or inputs.get("maximum_parseable_length") != 129
            or inputs.get("exact_length") != "2*N"
            or not isinstance(outputs, dict)
            or outputs.get("maximum_output_bytes") != 512
            or outputs.get("no_write_on_error") is not True
            or not isinstance(workspace, dict)
            or workspace.get("bytes", 0) < 72 * 1024
            or not isinstance(measurement, dict)
            or measurement.get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload identity, ABI limits, or scratch budget differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(length) is not int
                or type(input_null) is not bool or type(output_null) is not bool
                or type(capacity) is not int or capacity < 0
                or (input_null and (values or length != 0))
                or (not input_null and (length != len(values) or length > 129))):
            issues.append(f"invalid frame or output flags: {case_id}")
            continue
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        primary_result = primary(values, capacity, output_null, input_null, length)
        independent_result = independent(values, capacity, output_null, input_null, length)
        try:
            expected = (expected_result, bytes.fromhex(expected_hex))
        except (TypeError, ValueError):
            expected = None
        if (type(expected_result) is not int or not isinstance(expected_hex, str)
                or primary_result != independent_result or primary_result != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    required = {"singleton-negative-label", "two-modal-labels-at-root-and-child",
                "negative-tie-on-chain", "star-with-a-root-tie", "all-equal-labels",
                "parent-not-earlier-than-child", "color-out-of-range", "trailing-word",
                "malformed-input-precedes-null-output", "short-output", "null-output", "null-input"}
    if not required <= seen:
        issues.append("missing required workload cases: " + ", ".join(sorted(required - seen)))
    return issues


static_issues = verify_workload
