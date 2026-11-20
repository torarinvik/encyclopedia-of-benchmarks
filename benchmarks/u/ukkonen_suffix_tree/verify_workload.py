"""Static package and scalar fixture checks for online suffix-tree construction."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_DISTINCT_SUBSTRINGS,
    MAX_HASH,
    MAX_INPUT_LENGTH,
    MAX_NODES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_TEXT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/u/ukkonen_suffix_tree"
SYMBOL = "ukkonen_suffix_tree"
SOURCE_URL = "https://doi.org/10.1007/BF01206331"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
SERIALIZATION = (
    "Preorder from the root, with child edges ordered by first symbol. Begin with root token 0. "
    "For each edge emit [1, edge_length, each edge symbol plus 1, tag]. A leaf uses tag 2 "
    "followed by suffix_start+1; an internal node uses tag 3, its children, and closing token 4. "
    "Append closing token 4 after the root."
)
REQUIRED = {
    "empty-text-terminal-only", "one-symbol", "two-equal-symbols-suffix-links",
    "two-distinct-symbols", "invalid-empty-input", "null-input",
    "invalid-count-above-bound", "invalid-symbol", "invalid-truncated-text",
    "invalid-trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "u" / f"{SYMBOL}.{extension}"
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
    if (workload.get("id") != "ukkonen-online-suffix-tree-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("encoding") != "[n, symbol_0, ..., symbol_(n-1)]"
            or input_spec.get("text_length_range") != [0, MAX_TEXT_LENGTH]
            or input_spec.get("symbol_range") != [0, 3]
            or input_spec.get("terminator") != 4
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1
            or profile.get("maximum_nodes") != MAX_NODES
            or profile.get("construction") != "Process each text symbol from left to right, maintaining the active reference pair, suffix links, open leaf ends, and update/canonize/test-and-split transitions."
            or profile.get("maximum_serialization_tokens") != 8_903
            or profile.get("maximum_distinct_substrings") != MAX_DISTINCT_SUBSTRINGS
            or profile.get("maximum_token_hash") != MAX_HASH
            or profile.get("canonical_serialization") != SERIALIZATION):
        issues.append("workload identity, input framing, serialization, or bounds differ")

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
            issues.append(f"online-construction fixture mismatch: {case_id}")
        if independent(values, input_is_null, length) != expected:
            issues.append(f"suffix-trie fixture mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
