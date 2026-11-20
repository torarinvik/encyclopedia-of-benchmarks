"""Static package and fixture inventory; reads source and workload only."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH, MAX_RESULT, MAX_TEXT_LENGTH,
    MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES, expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/d/distinct_substring_count_hashing"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
SYMBOL = "distinct_substring_count_hashing"
SOURCE_URL = "https://cp-algorithms.com/string/string-hashing.html#determine-the-number-of-different-substrings-in-a-string"
REQUIRED_CASES = {
    "empty", "singleton", "repeated-symbols", "overlapping-periodic",
    "hash-collision-remains-distinct", "full-byte-range",
    "all-distinct-maximum-length", "maximum-length-repeated", "length-above-bound",
    "invalid-negative-symbol", "invalid-symbol-above-byte", "trailing-value",
    "missing-symbol", "missing-length", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json", "verify_workload.py",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "d" / f"{SYMBOL}.{extension}"
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
    algorithm_spec = workload.get("method", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or input_spec.get("text_length_range") != [0, MAX_TEXT_LENGTH]
            or input_spec.get("symbol_range") != [0, 255]
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_result") != -1
            or output_spec.get("result_range") != f"0..{MAX_RESULT}"
            or output_spec.get("invalid_result") != -1
            or algorithm_spec.get("hash") != "H(s)=H(prefix)*257+(byte+1) modulo 1000000007"
            or algorithm_spec.get("collision_policy") != "same-length equal hashes are byte-compared; colliding but unequal substrings remain separate"
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload identity, bounds, collision rule, or workspace differs")
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
        is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(is_null) is not bool
                or type(input_length) is not int
                or (is_null and (values or input_length != 0))
                or (not is_null and input_length != len(values))
                or type(expected) is not int):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if (primary(values, input_is_null=is_null, input_length=input_length) != expected
                or independent(values, input_is_null=is_null, input_length=input_length) != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues
