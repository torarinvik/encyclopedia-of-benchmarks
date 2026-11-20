"""Static metadata, fixture, and source-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_RESULT,
    MAX_SYMBOLS,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/l/length_limited_huffman_package_merge"
SYMBOL = "length_limited_huffman_package_merge"
SOURCE_URL = "https://doi.org/10.1145/79147.79150"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "two-symbols-at-limit-one", "two-symbols-with-slack",
    "three-symbol-constrained-optimum", "four-symbol-complete-tree",
    "five-equal-symbols", "length-bound-forces-long-light-codes",
    "six-equal-symbols", "zero-weight-symbols", "maximum-symbols-and-weights",
    "null-input", "empty-frame", "infeasible-depth-limit",
    "symbol-count-above-capacity", "negative-weight", "weight-above-bound",
    "truncated-weight-list", "trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "l" / f"{SYMBOL}.{extension}"
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
    if (workload.get("id") != "length-limited-huffman-package-merge-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[n,L,w_0,...,w_(n-1)]"
            or input_spec.get("symbol_count_range") != [2, MAX_SYMBOLS]
            or input_spec.get("maximum_code_length_range") != [1, 6]
            or input_spec.get("feasibility_rule") != "n<=2^L"
            or input_spec.get("weight_range") != [0, 1_000_000]
            or input_spec.get("exact_input_length") != "n+2"
            or input_spec.get("maximum_valid_input_length") != MAX_SYMBOLS + 2
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("objective") != "Find minimum sum(w_i*length_i) over binary prefix codes whose codeword lengths are at most L."
            or profile.get("nodeset_reduction") != "Each symbol i contributes a node of weight w_i and width 2^-d at each depth d in 1..L. A full binary tree with n leaves has nodeset width n-1."
            or profile.get("package_merge") != "Scale all widths by 2^L. Initialize one ascending-weight item for each symbol in every depth-width list and set the remaining target to (n-1)*2^L. Process widths from smallest upward. Let q be the least significant set bit of the remaining target width. If current width exceeds q, the instance is infeasible. If it equals q, select the lightest item and subtract q. Pair the remaining consecutive items from lightest upward into double-width packages, discard an unpaired heaviest item, and merge packages into the next width list."
            or profile.get("tie_breaking") != "Lists are sorted by nondecreasing item weight; equal-weight items may be selected in either order because only the optimal weighted cost is returned."
            or profile.get("complexity") != "O(nL) time and O(nL) auxiliary storage for n<=12 and L<=6."
            or profile.get("overflow_bound") != "The weighted code length is at most n*L*max_weight=72000000, within signed 64-bit range."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Minimum total weighted codeword length; -1 for invalid input."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, package-merge profile, or output bounds differ")

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
