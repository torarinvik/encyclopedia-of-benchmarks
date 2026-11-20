"""Static agreement checks for the bounded self-number workload."""

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

    if (workload.get("algorithm") != primary_oracle.ALGORITHM
            or workload.get("function_symbol") != primary_oracle.ALGORITHM
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, exported symbol, or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("N_range") != [1, primary_oracle.MAX_LIMIT]
            or input_spec.get("exact_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != primary_oracle.INVALID_RESULT):
        issues.append("input bounds differ from primary reference")
    output_spec = workload.get("output", {})
    if (output_spec.get("valid_result_range") != [primary_oracle.MIN_RESULT, primary_oracle.MAX_RESULT]
            or output_spec.get("invalid_input_result") != primary_oracle.INVALID_RESULT):
        issues.append("output bounds differ from primary reference")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES:
        issues.append("workspace cap differs from primary reference")

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
        "minimum-one", "first-digit-block", "first-self-number-at-twenty",
        "published-below-one-hundred", "one-hundred-is-self",
        "generated-one-hundred-one", "thousand-count-checkpoint",
        "ten-thousand-count-checkpoint", "maximum-limit", "zero-invalid",
        "negative-invalid", "above-domain-invalid", "trailing-word-invalid",
        "null-input", "i64-min-invalid", "i64-max-invalid",
    }
    if seen != required:
        issues.append("fixture IDs differ from the reviewed inventory")
    return issues
