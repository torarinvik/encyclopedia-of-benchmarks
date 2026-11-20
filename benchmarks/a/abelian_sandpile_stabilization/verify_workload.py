"""Static fixture and reference agreement checker for this package."""

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
    if (workload.get("algorithm") != "abelian_sandpile_stabilization"
            or workload.get("function_symbol") != "abelian_sandpile_stabilization"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    bounds = workload.get("input", {})
    if (bounds.get("rows_range") != [1, primary_oracle.MAX_ROWS]
            or bounds.get("cols_range") != [1, primary_oracle.MAX_COLS]
            or bounds.get("height_range") != [0, primary_oracle.MAX_HEIGHT]
            or bounds.get("exact_length") != "2+rows*cols"
            or bounds.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or bounds.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or bounds.get("invalid_input_result") != primary_oracle.INVALID_RESULT):
        issues.append("input bounds differ from primary reference")
    output = workload.get("output", {})
    if output.get("valid_result_range") != [0, primary_oracle.MAX_RESULT]:
        issues.append("packed-result bound differs from primary reference")
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
        kwargs = {"input_is_null": case.get("input_is_null", False),
                  "input_length": case["input_length"]}
        expected = case.get("expected_result")
        if primary_oracle.expected_result(values, **kwargs) != expected:
            issues.append(f"primary result mismatch: {case_id}")
        if independent_oracle.expected_result(values, **kwargs) != expected:
            issues.append(f"independent result mismatch: {case_id}")
    required = {
        "single-cell-empty", "single-cell-sink-topple", "stable-mixed-2x2",
        "one-corner-topple", "two-corner-topples", "multi-site-cascade",
        "maximum-packed-stable-board", "maximum-valid-frame", "zero-rows-invalid",
        "too-many-rows-invalid", "negative-height-invalid", "height-over-maximum-invalid",
        "truncated-frame-invalid", "trailing-word-invalid",
        "maximum-parseable-trailing-word-invalid", "null-input",
        "i64-min-invalid", "i64-max-invalid",
    }
    if seen != required:
        issues.append("fixture IDs differ from the reviewed inventory")
    return issues
