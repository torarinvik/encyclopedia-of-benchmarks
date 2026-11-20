"""Static source inventory and sparse workload fixture checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/h/hough_line_transform"
SYMBOL = "hough_line_transform"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "empty-one-pixel-grid", "origin-pixel-votes-at-rho-zero",
    "all-pixels-in-two-by-two-grid", "main-diagonal-two-by-two-grid",
    "maximum-dimensions-corner-pixel", "zero-height", "width-above-maximum",
    "trailing-word-after-valid-grid", "non-binary-pixel",
    "null-input", "short-output-capacity", "null-output",
}
SOURCE_URL = "https://doi.org/10.1145/361237.361242"


def _sparse_output(case: dict) -> bytes | None:
    entries = case.get("expected_output_nonzero_bins")
    if not isinstance(entries, list):
        return None
    output = bytearray(MAX_OUTPUT_BYTES)
    previous_index = -1
    for entry in entries:
        if (not isinstance(entry, list) or len(entry) != 2
                or type(entry[0]) is not int or type(entry[1]) is not int):
            return None
        index, count = entry
        if (not 0 <= index < MAX_OUTPUT_BYTES or not 1 <= count <= 64
                or index <= previous_index):
            return None
        output[index] = count
        previous_index = index
    return bytes(output)


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in PORTS.items():
        source = ROOT / language / "h" / f"{SYMBOL}.{extension}"
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
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    profile = workload.get("algorithm_profile", {})
    source_spec = workload.get("source", {})
    workspace = workload.get("workspace", {})
    measurement = workload.get("measurement", {})
    if not all(isinstance(value, dict) for value in
               (input_spec, output_spec, profile, source_spec, workspace, measurement)):
        return issues + ["workload contract sections must be objects"]
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("maximum_height") != 8
            or input_spec.get("maximum_width") != 8
            or input_spec.get("pixel_values") != [0, 1]
            or input_spec.get("invalid_input_writes_bytes") is not False
            or output_spec.get("byte_count") != MAX_OUTPUT_BYTES
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("insufficient_output_capacity_result") != -2
            or output_spec.get("null_output_result") != -2
            or output_spec.get("errors_write_bytes") is not False
            or profile.get("integer_normals_in_order") != [[1, 0], [1, 1], [0, 1], [-1, 1]]
            or profile.get("rho_minimum") != -14
            or profile.get("rho_maximum") != 14
            or profile.get("rho_bin_count") != 29
            or profile.get("maximum_bin_count") != 64
            or source_spec.get("url") != SOURCE_URL
            or workspace.get("bytes") != MAX_OUTPUT_BYTES
            or measurement.get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload identity, Hough profile, bounds, or ABI differ from contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        input_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        expected_result = case.get("expected_result")
        expected_bytes = _sparse_output(case)
        if (not isinstance(values, list) or type(input_null) is not bool
                or type(input_length) is not int or type(output_null) is not bool
                or type(capacity) is not int or type(expected_result) is not int
                or expected_bytes is None):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if (expected_result < 0 and expected_bytes != bytes(MAX_OUTPUT_BYTES)
                or primary(values, capacity=capacity, output_is_null=output_null,
                           input_is_null=input_null, input_length=input_length)
                != (expected_result, b"" if expected_result < 0 else expected_bytes)
                or independent(values, capacity=capacity, output_is_null=output_null,
                               input_is_null=input_null, input_length=input_length)
                != (expected_result, b"" if expected_result < 0 else expected_bytes)):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
