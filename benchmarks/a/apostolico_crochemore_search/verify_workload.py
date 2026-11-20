"""Static workload and port inventory for Apostolico-Crochemore search."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    COUNT_SHIFT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_TEXT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    SUM_SHIFT,
    WORKSPACE_BYTES,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/a/apostolico_crochemore_search"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
SYMBOL = "apostolico_crochemore_search"
REQUIRED = {
    "overlapping-periodic", "repeated-prefix-matches", "single-symbol-multiple-hits",
    "whole-text-match", "no-match", "pattern-longer-than-text", "empty-text",
    "text-too-large", "empty-pattern", "symbol-outside-alphabet",
    "pattern-symbol-outside-alphabet", "trailing-word",
    "missing-header", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "a" / f"{SYMBOL}.{extension}"
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
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != "https://www-igm.univ-mlv.fr/~lecroq/string/node12.html"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[n,m,text[0..n),pattern[0..m)]"
            or input_spec.get("text_length_range") != [0, MAX_TEXT_LENGTH]
            or input_spec.get("pattern_length_range") != [1, MAX_PATTERN_LENGTH]
            or input_spec.get("alphabet_range") != [0, 3]
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_result") != -1
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("encoding") != "(match_count << 36) | (sum_of_offsets << 12) | xor_of_offsets"
            or output_spec.get("result_range") != "0..562949953421311"
            or output_spec.get("invalid_result") != -1
            or workload.get("complexity", {}).get("time") != "O(n+m)"
            or workload.get("complexity", {}).get("auxiliary_space") != "O(n+m)"
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or COUNT_SHIFT != 36 or SUM_SHIFT != 12):
        issues.append("workload identity, search bounds, packed result, or workspace differs")

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
        primary_result = primary(values, input_is_null=is_null, input_length=input_length)
        independent_result = independent(values, input_is_null=is_null, input_length=input_length)
        if primary_result != expected or independent_result != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
