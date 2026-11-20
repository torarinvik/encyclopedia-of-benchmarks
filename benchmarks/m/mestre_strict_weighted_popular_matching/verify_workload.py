"""Static workload and dual-reference agreement review."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_result as independent_result
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
SYMBOL = "mestre_strict_weighted_popular_matching"
REQUIRED_CASES = {
    "single-applicant-first-choice", "separate-first-jobs",
    "equal-weight-shared-first-job", "higher-category-gets-contested-first-job",
    "promotion-label-chain-rejects", "maximum-valid-frame", "duplicate-job-in-row",
    "zero-weight", "truncated-row", "trailing-word-at-parseable-bound",
    "null-input-at-parseable-bound",
}


def verify_workload(workload: dict[str, Any] | None = None) -> list[str]:
    """Return static contract/reference issues; this function is never invoked here."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("maximum_result") != 1
            or workload.get("workspace", {}).get("bytes") != 4096
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload identity, bounds, result convention, or workspace differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != REQUIRED_CASES:
        issues.append("fixture IDs are duplicated or differ from the static inventory")
    by_id = {case["id"]: case for case in cases}
    maximum = by_id.get("maximum-valid-frame", {})
    trailing = by_id.get("trailing-word-at-parseable-bound", {})
    null_case = by_id.get("null-input-at-parseable-bound", {})
    if (maximum.get("input_length") != MAX_VALID_INPUT_LENGTH
            or len(maximum.get("input_values", [])) != MAX_VALID_INPUT_LENGTH):
        issues.append("maximum-valid-frame does not exercise the valid upper bound")
    if (trailing.get("input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or trailing.get("input_values", [])[:-1] != maximum.get("input_values")):
        issues.append("trailing fixture must append one word to the maximum valid frame")
    if (null_case.get("input_is_null") is not True
            or null_case.get("input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or null_case.get("input_values") != []):
        issues.append("null fixture must use an empty buffer and parseable-bound length")

    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(is_null) is not bool
                or type(case.get("expected_result")) is not int):
            issues.append(f"malformed fixture metadata: {case_id}")
            continue
        if (is_null and values) or (not is_null and length != len(values)):
            issues.append(f"fixture length/null metadata mismatch: {case_id}")
            continue
        args = {"input_is_null": is_null, "input_length": length}
        actual_primary = primary_result(values, **args)
        actual_independent = independent_result(values, **args)
        if actual_primary != actual_independent:
            issues.append(f"references disagree for {case_id}: {actual_primary} vs {actual_independent}")
        if actual_primary != case["expected_result"]:
            issues.append(f"fixture result mismatch for {case_id}: expected {case['expected_result']}, got {actual_primary}")
    return issues
