"""Static workload and dual-reference review for HsaDelta."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_expected
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_output as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "hsadelta_differential_compression":
        issues.append("workload algorithm differs from the package name")
    if workload.get("function_symbol") != "hsadelta_differential_compression":
        issues.append("workload function symbol differs from the package name")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("reference_length_range") != [0, 32]
            or input_meta.get("version_length_range") != [0, 32]
            or input_meta.get("block_size_range") != [2, 4]
            or input_meta.get("byte_range") != [0, 255]):
        issues.append("input bounds differ from the bounded profile")
    output_meta = workload.get("output", {})
    if (output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("success_result") != "bytes written"
            or output_meta.get("invalid_input_result") != -1
            or output_meta.get("output_error_result") != -2):
        issues.append("output metadata differs from the bounded profile")
    if workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES:
        issues.append("workspace metadata differs from the bounded profile")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("each workload case must be an object")
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        expected = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        primary = primary_expected(values, capacity, output_null, input_null, length)
        independent = independent_expected(values, capacity, output_null, input_null, length)
        label = case.get("id", "<unnamed>")
        if primary != independent:
            issues.append(f"{label}: independent references disagree")
        if primary[0] != expected or primary[1].hex() != expected_hex:
            issues.append(f"{label}: expected output differs from both references")
    return issues
