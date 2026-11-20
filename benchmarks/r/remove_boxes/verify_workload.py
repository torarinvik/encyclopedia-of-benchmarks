"""Static workload metadata and dual-reference checks for remove_boxes."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    INVALID_RESULT,
    MAX_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "remove_boxes":
        issues.append("workload algorithm must be remove_boxes")
    if workload.get("function_symbol") != "remove_boxes":
        issues.append("workload function symbol must be remove_boxes")
    input_meta = workload.get("input", {})
    if input_meta.get("maximum_valid_length") != MAX_INPUT_LENGTH:
        issues.append("maximum valid input length differs from the primary reference")
    if input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length differs from the primary reference")
    if input_meta.get("n_range") != [0, 18] or input_meta.get("color_range") != [0, 7]:
        issues.append("input bounds differ from the primary reference")
    output_meta = workload.get("output", {})
    if (output_meta.get("kind") != "signed_64_bit_integer"
            or output_meta.get("maximum_result") != 324
            or output_meta.get("invalid_input_result") != INVALID_RESULT):
        issues.append("output bounds differ from the primary reference")
    if workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES:
        issues.append("workspace size differs from the bounded memo table")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("each workload case must be an object")
            continue
        values = case.get("input_values")
        null_input = case.get("input_is_null", False)
        length = case.get("input_length")
        expected = case.get("expected_result")
        primary = primary_expected(values, null_input, length)
        independent = independent_expected(values, null_input, length)
        if primary != independent:
            issues.append(f"{case.get('id', '<unnamed>')}: references disagree")
        if expected != primary:
            issues.append(f"{case.get('id', '<unnamed>')}: expected result differs from references")
    return issues
