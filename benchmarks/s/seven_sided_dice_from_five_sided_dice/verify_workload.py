"""Static workload, reference, documentation, and ten-port inventory."""

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
PACKAGE = ROOT / "benchmarks/s/seven_sided_dice_from_five_sided_dice"
SYMBOL = "seven_sided_dice_from_five_sided_dice"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "direct-acceptance", "rejected-tail-is-recycled",
    "accepted-quotient-entropy-is-reused",
    "finite-tape-exhausts-after-rejections",
    "one-draw-has-insufficient-entropy", "zero-draw-tape", "trailing-word",
    "negative-count", "count-over-bound", "truncated-draw-tape",
    "draw-out-of-range", "negative-draw", "short-output-capacity",
    "null-output", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in PORTS.items():
        source = ROOT / language / "s" / f"{SYMBOL}.{extension}"
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
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
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
        input_length = case.get("input_length")
        output_capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if (not isinstance(values, list) or type(input_length) is not int
                or type(output_capacity) is not int or type(input_is_null) is not bool
                or type(output_is_null) is not bool or type(expected_result) is not int
                or not isinstance(expected_hex, str)):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid expected output hex: {case_id}")
            continue
        primary_result, primary_bytes = primary(
            values, output_capacity, output_is_null, input_is_null, input_length)
        independent_result, independent_bytes = independent(
            values, output_capacity, output_is_null, input_is_null, input_length)
        recorded = (expected_result, expected_bytes)
        if (primary_result, primary_bytes) != recorded:
            issues.append(f"primary reference differs from fixture: {case_id}")
        if (independent_result, independent_bytes) != recorded:
            issues.append(f"independent reference differs from fixture: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("required fixture case set differs")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8") if (PACKAGE / "README.md").is_file() else ""
    for language, extension in PORTS.items():
        relative = f"../../../{language}/s/{SYMBOL}.{extension}"
        if f"]({relative})" not in readme:
            issues.append(f"README link missing for {language}")
    return issues


static_issues = verify_workload


if __name__ == "__main__":
    verify_workload()
