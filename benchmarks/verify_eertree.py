#!/usr/bin/env python3
"""Statically check the eertree workload against the substring oracle."""

from __future__ import annotations

import json
from pathlib import Path
import sys

from eertree_oracle import (
    ALPHABET_SIZE,
    INVALID_RESULT,
    MAX_INPUT_LENGTH,
    MAX_TEXT_LENGTH,
    SOURCE_BASIS,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}
CASE_IDS = {
    "empty_text",
    "single_letter",
    "one_repeated_letter",
    "alternating_odd_palindromes",
    "nested_palindrome_growth",
    "even_palindrome_extension",
    "new_character_only",
    "prefix_adds_no_new_palindrome",
    "distinct_palindrome_count_after_branching",
    "all_lowercase_letters_once",
    "invalid_negative_letter_code",
    "invalid_letter_code_above_alphabet",
    "mismatched_text_length",
    "text_length_above_limit",
    "null_input_pointer_with_positive_length",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "eertree-distinct-palindrome-prefixes-v1", "workload id mismatch")
    require(workload.get("algorithm") == "eertree", "algorithm name mismatch")
    require(workload.get("function_symbol") == "eertree", "function symbol mismatch")
    require(workload.get("source_basis") == SOURCE_BASIS, "source provenance metadata mismatch")
    require(workload.get("input") == {
        "kind": "packed_lowercase_ascii_letter_code_array",
        "encoding": "[text_length, letter_0, ..., letter_(n-1)]",
        "minimum_text_length": 0,
        "maximum_text_length": MAX_TEXT_LENGTH,
        "maximum_valid_input_length": MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_INPUT_LENGTH,
        "letter_code_range": [0, ALPHABET_SIZE - 1],
        "letter_code_mapping": "0=a through 25=z",
        "invalid_result": INVALID_RESULT,
        "null_input_result": INVALID_RESULT,
    }, "input contract metadata mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_integer",
        "meaning": "Sum over one-based prefixes of prefix_length times the number of distinct nonempty palindromic substrings in that prefix.",
        "empty_text_result": 0,
        "invalid_result": INVALID_RESULT,
    }, "output contract metadata mismatch")
    require(workload.get("measurement") == {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": 9,
        "warmup_rounds": 1,
        "repetitions_per_sample": 20,
    }, "measurement metadata mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "workload cases must be an array")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)]
    require(len(case_ids) == len(cases) and len(set(case_ids)) == len(case_ids), "case IDs must be unique")
    require(set(case_ids) == CASE_IDS, "workload fixture set mismatch")
    for case in cases:
        values = case.get("input_values")
        is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        require(isinstance(values, list), f"{case['id']}: input_values must be a list")
        require(type(is_null) is bool, f"{case['id']}: null flag must be boolean")
        require(type(input_length) is int, f"{case['id']}: input length must be an integer")
        require(type(case.get("expected_result")) is int, f"{case['id']}: expected result must be an integer")
        if is_null:
            require(case["id"] == "null_input_pointer_with_positive_length", "unexpected null-input fixture")
            require(values == [] and 1 <= input_length <= MAX_INPUT_LENGTH, "null-input framing mismatch")
        else:
            require(input_length == len(values), f"{case['id']}: packed length mismatch")
        result = expected_result(values, input_is_null=is_null, input_length=input_length)
        require(result == case["expected_result"], f"{case['id']}: substring oracle mismatch")


def validate_sources() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "e" / f"eertree.{extension}"
        require(source.is_file(), f"missing {language} eertree source")
        require("eertree" in source.read_text(encoding="utf-8"), f"{language} source is missing its export")


def main() -> int:
    workload_path = ROOT / "benchmarks/e/eertree/workload.json"
    readme_path = ROOT / "benchmarks/e/eertree/README.md"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = readme_path.read_text(encoding="utf-8")
    for source in SOURCE_BASIS:
        require(source["url"] in readme, f"README is missing provenance URL: {source['title']}")
    print("eertree static contract, substring oracle, provenance, and nine source paths checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL eertree static verification: {error}", file=sys.stderr)
        raise SystemExit(1)
