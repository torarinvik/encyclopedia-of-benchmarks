"""Static package inventory and fixture consistency checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/z/zhang_suen_thinning"
SYMBOL = "zhang_suen_thinning"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-pixel-image", "empty-three-by-three-image",
    "two-by-two-interior-block-is-removed-together",
    "three-by-three-interior-block-reduces-to-center",
    "dimension-out-of-range", "trailing-input-word", "non-binary-pixel",
    "short-output-capacity",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in PORTS.items():
        source = ROOT / language / "z" / f"{SYMBOL}.{extension}"
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
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_bytes_output_call"):
        issues.append("workload identity, bounds, byte-output contract, or workspace differs")

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
        expected_hex = case.get("expected_output_hex")
        if (not isinstance(values, list) or type(input_null) is not bool
                or type(input_length) is not int or type(output_null) is not bool
                or type(capacity) is not int or type(expected_result) is not int
                or not isinstance(expected_hex, str)):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if input_null:
            if values or input_length != 0:
                issues.append(f"invalid null-input fields: {case_id}")
                continue
        elif input_length != len(values):
            issues.append(f"input length mismatch: {case_id}")
            continue
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid output hex: {case_id}")
            continue
        args = dict(capacity=capacity, output_is_null=output_null,
                    input_is_null=input_null, input_length=input_length)
        if (primary(values, **args) != (expected_result, expected_bytes)
                or independent(values, **args) != (expected_result, expected_bytes)):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
