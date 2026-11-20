"""Static metadata, fixture, and source-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALUES,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/e/elias_fano_monotone_sequence"
SYMBOL = "elias_fano_monotone_sequence"
SOURCE_URL = "https://doi.org/10.1145/321812.321820"
IMPLEMENTATION_NOTES_URL = "https://pages.di.unipi.it/pibiri/papers/ii_compression.pdf"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "singleton-zero-universe", "sparse-values-with-wide-low-part",
    "dense-zero-low-width", "duplicate-values", "non-power-of-two-density",
    "large-single-value", "maximum-sequence-length", "null-input", "empty-frame",
    "universe-too-small", "negative-upper-bound", "upper-bound-above-limit",
    "value-above-upper-bound", "decreasing-sequence", "truncated-sequence",
    "trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "e" / f"{SYMBOL}.{extension}"
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
    if (workload.get("id") != "elias-fano-monotone-sequence-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or source.get("implementation_notes_url") != IMPLEMENTATION_NOTES_URL
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[n,U,x_0,...,x_(n-1)]"
            or input_spec.get("count_range") != [1, MAX_VALUES]
            or input_spec.get("inclusive_upper_bound_range") != [0, 1_000_000]
            or input_spec.get("feasibility_rule") != "n<=U+1"
            or input_spec.get("value_rule") != "0<=x_i<=U and x_i<=x_(i+1)"
            or input_spec.get("exact_input_length") != "n+2"
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("low_width") != "Choose the largest ell>=0 with n*2^ell<=U+1, equivalently floor(log2((U+1)/n))."
            or profile.get("low_encoding") != "Store x_i mod 2^ell for each sequence position i."
            or profile.get("high_encoding") != "Use a bit vector of length floor(U/2^ell)+n and set bit (x_i div 2^ell)+i for each i."
            or profile.get("access") != "Scan the high bit vector for one positions p_i and recover x_i=((p_i-i)*2^ell)|low_i."
            or profile.get("output_checksum") != "Return sum((i+1)*decoded_x_i) over all sequence positions."
            or profile.get("complexity") != "O(n+U/2^ell) time and O(n*ell+U/2^ell) bits of storage, with n<=32 and U<=1000000."
            or profile.get("overflow_bound") != "The checksum is at most (32*33/2)*1000000=528000000, within signed 64-bit range."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Position-weighted checksum of values accessed from the Elias-Fano representation; -1 for invalid input."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, Elias-Fano profile, or output bounds differ")

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
