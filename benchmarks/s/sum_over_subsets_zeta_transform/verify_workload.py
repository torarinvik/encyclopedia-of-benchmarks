"""Static metadata, fixture, and source-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_BITS,
    MAX_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/sum_over_subsets_zeta_transform"
SYMBOL = "sum_over_subsets_zeta_transform"
SOURCE_URL = "https://oi-wiki.org/basic/prefix-sum/"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "zero-dimensions-singleton", "one-dimension", "two-dimensional-distinct-values",
    "maximum-dimension-all-ones", "all-zero-function", "null-input", "empty-frame",
    "dimension-above-bound", "wrong-vector-length", "negative-function-value",
    "function-value-above-bound", "trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "s" / f"{SYMBOL}.{extension}"
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
    profile = workload.get("algorithm_profile", {})
    source = workload.get("source", {})
    measurement = workload.get("measurement", {})
    if (workload.get("id") != "sum-over-subsets-zeta-transform-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[B, f(0), ..., f(2^B-1)]"
            or input_spec.get("dimension_range") != [0, MAX_BITS]
            or input_spec.get("value_range") != [0, 1_000_000]
            or input_spec.get("exact_input_length") != "1+2^B"
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("transform") != (
                "For each bit b in ascending order and each mask containing b, add "
                "transformed[mask without b] into transformed[mask]. The result at S is "
                "the sum of f(T) for every T subset of S."
            )
            or profile.get("output_checksum") != "sum((mask+1)*transformed[mask]) over every mask."
            or profile.get("complexity") != "O(B*2^B) time and O(2^B) auxiliary space for B<=6."
            or profile.get("overflow_bound") != "For B<=6 and values<=1000000, the checksum is at most 133120000000, within signed 64-bit range."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Weighted checksum of the full subset zeta transform; -1 for invalid input."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, transform profile, or output bounds differ")

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
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if primary(values, input_is_null, length) != expected:
            issues.append(f"primary-reference fixture mismatch: {case_id}")
        if independent(values, input_is_null, length) != expected:
            issues.append(f"independent-reference fixture mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
