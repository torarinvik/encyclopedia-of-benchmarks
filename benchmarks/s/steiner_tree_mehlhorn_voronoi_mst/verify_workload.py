"""Static workload/reference reconciler; this file is not run during drafting."""
from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != primary_oracle.SYMBOL:
        issues.append("algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if input_meta.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if input_meta.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if output_meta.get("maximum_bytes") != primary_oracle.MAX_OUTPUT_BYTES:
        issues.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.MAX_WORKSPACE_BYTES:
        issues.append("workspace bound mismatch")
    cases = workload.get("cases", [])
    for case in cases:
        name = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        length = case.get("input_length")
        if type(length) is not int or length != len(values):
            issues.append(f"{name}: length does not match input_values")
            continue
        try:
            expected = (int(case["expected_result"]), bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"{name}: malformed expected output: {error}")
            continue
        args = (values, case.get("output_capacity"), case.get("output_is_null", False),
                case.get("input_is_null", False), length)
        primary = primary_oracle.expected_output(*args)
        independent = independent_oracle.expected_output(*args)
        if primary != expected:
            issues.append(f"{name}: primary disagrees with pinned output")
        if independent != expected:
            issues.append(f"{name}: independent reference disagrees with pinned output")
        if primary != independent:
            issues.append(f"{name}: references disagree")
        if len(expected[1]) > primary_oracle.MAX_OUTPUT_BYTES:
            issues.append(f"{name}: output exceeds declared bound")
    if not cases:
        issues.append("workload contains no cases")
    return issues


def verify() -> list[str]:
    return workload_issues()
