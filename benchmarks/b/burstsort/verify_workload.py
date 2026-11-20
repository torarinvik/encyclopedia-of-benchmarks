"""Static package and scalar-fixture checks for Burstsort."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    BUCKET_THRESHOLD,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_STRINGS,
    MAX_STRING_LENGTH,
    MAX_TRIE_NODES,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/burstsort"
SYMBOL = "burstsort"
SOURCE_URL = "https://doi.org/10.1145/1005813.1041517"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "empty-list", "one-empty-string", "single-maximum-length-string",
    "root-burst-and-byte-order", "prefix-order-and-empty-string",
    "shared-prefix-multi-level-burst", "duplicate-strings-cross-threshold",
    "maximum-string-count-empty-keys", "maximum-valid-frame",
    "maximum-parseable-length-trailing-word", "invalid-empty-input", "null-input",
    "invalid-count-above-bound", "invalid-truncated-record",
    "invalid-string-length", "invalid-byte", "invalid-trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "b" / f"{SYMBOL}.{extension}"
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
    if (workload.get("id") != "algorithm-burstsort-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("encoding") != "[n, (string_length, byte_0, ..., byte_(length-1))*n]"
            or input_spec.get("framing_rule") != "Every string has its own length word; all input words must be consumed exactly."
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("string_count_range") != [0, MAX_STRINGS]
            or input_spec.get("string_length_range") != [0, MAX_STRING_LENGTH]
            or input_spec.get("byte_range") != [0, 3]
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1
            or profile.get("bucket_threshold") != BUCKET_THRESHOLD
            or profile.get("burst_rule") != "When insertion makes a leaf bucket hold four non-ended strings, replace the bucket with a trie node and redistribute by the next byte. Ended strings use a separate terminal bucket and do not count toward the threshold."
            or profile.get("traversal") != "Emit terminal strings first, then local residual buckets in lexicographic order, then child nodes in byte order."
            or profile.get("residual_bucket_sorter") != "Insertion sort; each unburst leaf contains at most three non-ended strings."
            or profile.get("maximum_trie_nodes") != MAX_TRIE_NODES):
        issues.append("workload identity, input framing, output encoding, or bounds differ")

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
