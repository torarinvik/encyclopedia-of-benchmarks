"""Static oracle/workload reconciler; intentionally not executed during drafting."""
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
        issues.append("algorithm name mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    if input_contract.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid frame length mismatch")
    if input_contract.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable frame length mismatch")
    if output_contract.get("maximum_bytes") != primary_oracle.MAX_OUTPUT_BYTES:
        issues.append("maximum output length mismatch")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.MAX_WORKSPACE_BYTES:
        issues.append("workspace cap mismatch")

    for case in workload.get("cases", []):
        name = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        length = case.get("input_length")
        if type(length) is not int or length != len(values):
            issues.append(f"{name}: input_length does not match input_values")
            continue
        try:
            expected = (int(case["expected_result"]), bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"{name}: malformed expected output: {error}")
            continue
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        primary = primary_oracle.expected_output(
            values, capacity, output_is_null, input_is_null, length
        )
        independent = independent_oracle.expected_output(
            values, capacity, output_is_null, input_is_null, length
        )
        if primary != expected:
            issues.append(f"{name}: primary reference disagrees with pinned result")
        if independent != expected:
            issues.append(f"{name}: cut reference disagrees with pinned result")
        if primary != independent:
            issues.append(f"{name}: references disagree")
        if len(expected[1]) > primary_oracle.MAX_OUTPUT_BYTES:
            issues.append(f"{name}: output exceeds maximum")
    if not workload.get("cases"):
        issues.append("workload has no cases")
    return issues


def verify() -> list[str]:
    return workload_issues()
