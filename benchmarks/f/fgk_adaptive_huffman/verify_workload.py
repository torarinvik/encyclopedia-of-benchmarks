"""Static fixture comparison for the FGK profile."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_expected
from .primary_oracle import (
    ALPHABET, MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SYMBOLS, MAX_WORKSPACE_BYTES, expected_output as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "fgk_adaptive_huffman":
        issues.append("workload algorithm differs from package name")
    if workload.get("function_symbol") != "fgk_adaptive_huffman":
        issues.append("workload symbol differs from package name")
    meta = workload.get("input", {})
    if (meta.get("maximum_valid_length") != MAX_INPUT_LENGTH
            or meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or meta.get("symbol_count_range") != [0, MAX_SYMBOLS]
            or meta.get("alphabet_size") != ALPHABET):
        issues.append("input metadata differs from bounded profile")
    output = workload.get("output", {})
    if output.get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("output bound differs from bounded profile")
    if workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES:
        issues.append("workspace differs from bounded profile")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        length = case.get("input_length")
        result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        capacity = case.get("output_capacity")
        output_null = case.get("output_is_null", False)
        input_null = case.get("input_is_null", False)
        primary = primary_expected(values, capacity, output_null, input_null, length)
        independent = independent_expected(values, capacity, output_null, input_null, length)
        label = case.get("id", "<unnamed>")
        if primary != independent:
            issues.append(f"{label}: references disagree")
        if primary[0] != result or primary[1].hex() != expected_hex:
            issues.append(f"{label}: expected bytes differ from references")
    return issues
