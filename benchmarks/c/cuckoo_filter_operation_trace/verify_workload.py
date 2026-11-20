"""Static workload and dual-reference consistency review."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output  # type: ignore[no-redef]
    from primary_oracle import expected_output as primary_output  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "cuckoo_filter_operation_trace"
            or workload.get("function_symbol") != "cuckoo_filter_operation_trace"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_spec, dict)
            or input_spec.get("operation_count_range") != [1, 32]
            or input_spec.get("primary_bucket_range") != [0, 7]
            or input_spec.get("fingerprint_range") != [1, 15]
            or input_spec.get("maximum_valid_length") != 97
            or input_spec.get("maximum_parseable_length") != 98
            or input_spec.get("input_modified") is not False
            or input_spec.get("invalid_input_result") != -1
            or input_spec.get("null_input_result") != -1):
        issues.append("input framing or bounds differ")
    if (not isinstance(output_spec, dict)
            or output_spec.get("maximum_bytes") != 256
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -2
            or output_spec.get("kick_limit_result") != -3
            or output_spec.get("no_write_on_error") is not True):
        issues.append("output contract differs")
    if not isinstance(workspace, dict) or workspace.get("bytes") != 1024:
        issues.append("workspace metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or length != len(values) or type(expected_result) is not int
                or not isinstance(expected_hex, str) or type(input_is_null) is not bool
                or type(output_is_null) is not bool
                or type(capacity) is not int):
            issues.append(f"invalid case fields: {case_id}")
            continue
        try:
            primary = primary_output(
                values, capacity=capacity, output_is_null=output_is_null,
                input_is_null=input_is_null, input_length=length,
            )
            independent = independent_output(
                values, capacity=capacity, output_is_null=output_is_null,
                input_is_null=input_is_null, input_length=length,
            )
        except (TypeError, ValueError, OverflowError) as error:
            issues.append(f"reference raised for {case_id}: {error}")
            continue
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid expected output hex: {case_id}")
            continue
        expected = (expected_result, expected_bytes)
        if primary != expected:
            issues.append(f"primary output differs from fixture: {case_id}")
        if independent != expected:
            issues.append(f"independent output differs from fixture: {case_id}")
        if primary != independent:
            issues.append(f"references disagree: {case_id}")
    return issues


static_issues = verify_workload


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
