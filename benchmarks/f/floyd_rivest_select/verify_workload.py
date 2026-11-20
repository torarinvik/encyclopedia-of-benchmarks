"""Static metadata, fixture, and source-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_ITEMS,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    SAMPLE_THRESHOLD,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/floyd_rivest_select"
SYMBOL = "floyd_rivest_select"
SOURCE_URL = "https://doi.org/10.1145/360680.360694"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "single-item", "below-cutoff", "sample-window-cutoff",
    "sample-window-minimum-rank", "sample-window-maximum-rank",
    "maximum-count-middle-rank", "maximum-count-minimum-rank", "maximum-value",
    "null-input", "empty-frame", "rank-out-of-range", "duplicate-values",
    "negative-value", "count-above-bound", "trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "f" / f"{SYMBOL}.{extension}"
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
    if (workload.get("id") != "floyd-rivest-rank-centered-select-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or source.get("analysis_url") != "https://people.csail.mit.edu/rivest/pubs/FR75a.pdf"
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[n, k, value_0, ..., value_(n-1)]"
            or input_spec.get("item_count_range") != [1, MAX_ITEMS]
            or input_spec.get("rank_range") != "0 <= k < n (zero-based)"
            or input_spec.get("value_range") != [0, MAX_RESULT]
            or input_spec.get("distinct_values") is not True
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("identity") != "Floyd–Rivest Algorithm 489 rank-centered sample-window pivot estimator followed by duplicate-safe three-way partitioning."
            or profile.get("sample_cutoff") != (
                f"Enter the sample-window branch when the active inclusive segment has R-L > {SAMPLE_THRESHOLD}. "
                "The published listing uses 600; this profile uses a smaller, documented workload cutoff because the paper states it was machine tuned."
            )
            or profile.get("sample_window") != (
                "For N=R-L+1 and i=K-L+1, compute z=sqrt(ln N), s=0.5*exp(2z/3), and "
                "sd=0.5*sqrt(z*s*(N-s)/N)*sign(i-N/2). Estimate LL=K-i*s/N+sd and "
                "RR=K+(N-i)*s/N+sd; round LL down and RR up, clamp to [L,K] and [K,R], "
                "then recursively select K in that window."
            )
            or profile.get("partition") != (
                "Copy input, pivot on the selected value at K, partition the active segment into "
                "less/equal/greater regions, and continue only in the region containing K."
            )
            or profile.get("rounding") != "Binary64 estimates; floor the lower endpoint and ceil the upper endpoint before clamping."
            or profile.get("complexity") != "For this bounded profile, O(n^2) worst-case time and O(n) auxiliary space, including the copied array and sample recursion."
            or profile.get("tie_breaking") != "Values must be distinct; invalid duplicate inputs return -1."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Value at zero-based sorted rank k; -1 for invalid input."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, profile, or output bounds differ")

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
