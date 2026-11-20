"""Static package and fixture contract review for AVR speed scaling."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import MAX_INPUT_LENGTH as INDEPENDENT_MAX_INPUT
from .independent_oracle import MAX_OUTPUT as INDEPENDENT_MAX_OUTPUT
from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT,
    MAX_OUTPUT_VALUES,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/a/avr_speed_scaling"
SYMBOL = "avr_speed_scaling"
SOURCE_URL = "https://doi.org/10.1007/s00453-009-9379-z"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "one-job-unit-speed", "fractional-average-rate", "separated-windows",
    "edf-across-speed-changes", "nonpositive-window", "trailing-value",
    "insufficient-output-capacity", "null-output", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "a" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
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
    if (workload.get("id") != "encyclopedia-avr-speed-scaling-i64-array-bytes-output-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[job_count,(release,deadline,work)*]"
            or input_spec.get("job_count_range") != [1, 8]
            or input_spec.get("time_range") != [0, 8]
            or input_spec.get("work_range") != [1, 8]
            or input_spec.get("maximum_valid_length") != MAX_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != INDEPENDENT_MAX_INPUT
            or output_spec.get("kind") != "little_endian_signed_64_bit_array"
            or output_spec.get("maximum_values") != MAX_OUTPUT_VALUES
            or output_spec.get("maximum_bytes") != MAX_OUTPUT
            or workload.get("workspace") != {
                "bytes": MAX_OUTPUT,
                "meaning": "Maximum output-buffer capacity for the 79-field exact speed and completion trace.",
            }
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -2):
        issues.append("workload identity, job domain, output format, or bounds differ")

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
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        expected = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(capacity) is not int or capacity < 0 or type(expected) is not int
                or not isinstance(expected_hex, str) or type(input_is_null) is not bool
                or type(output_is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        primary_result, primary_bytes = primary(
            values, capacity, output_is_null, input_is_null, length)
        independent_result, independent_bytes = independent(
            values, capacity, output_is_null, input_is_null, length)
        if (primary_result != expected or independent_result != expected
                or primary_bytes.hex() != expected_hex.lower()
                or independent_bytes != primary_bytes):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
