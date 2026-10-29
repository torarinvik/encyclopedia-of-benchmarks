#!/usr/bin/env python3
"""Statically check the Li Chao tree contract, fixtures, provenance, and port set."""

from __future__ import annotations

import json
from pathlib import Path
import sys

from li_chao_tree_oracle import (
    CHECKSUM_OFFSET,
    COEFFICIENT_LIMIT,
    DOMAIN_HIGH,
    DOMAIN_LOW,
    INVALID_RESULT,
    MAX_INPUT_LENGTH,
    MAX_OPERATIONS,
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
    "single_line_at_origin",
    "crossing_lines_at_three_points",
    "parallel_lines_and_intercepting_constant",
    "empty_operation_trace",
    "minimum_value_and_checksum_offset_boundary",
    "repeated_queries_are_position_weighted",
    "maximum_positive_line_value",
    "invalid_opcode",
    "invalid_slope",
    "invalid_intercept",
    "query_before_first_line",
    "query_outside_domain",
    "query_reserved_field_nonzero",
    "truncated_operation_record",
    "operation_count_above_limit",
    "null_input_pointer_with_positive_length",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "li-chao-tree-online-minimum-v1", "workload id mismatch")
    require(workload.get("algorithm") == "li_chao_tree", "algorithm name mismatch")
    require(workload.get("function_symbol") == "li_chao_tree", "function symbol mismatch")
    require(workload.get("source_basis") == SOURCE_BASIS, "source provenance metadata mismatch")

    expected_input = {
        "kind": "packed_signed_64_bit_integer_array",
        "encoding": "[operation_count, (opcode, first, second)...]",
        "maximum_operations": MAX_OPERATIONS,
        "maximum_valid_input_length": MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_INPUT_LENGTH,
        "domain": [DOMAIN_LOW, DOMAIN_HIGH],
        "slope_and_intercept_range": [-COEFFICIENT_LIMIT, COEFFICIENT_LIMIT],
        "add_line_record": {"opcode": 0, "fields": ["slope", "intercept"]},
        "query_record": {"opcode": 1, "fields": ["x", "reserved_zero"]},
        "queries_require_a_prior_line": True,
        "invalid_result": INVALID_RESULT,
        "null_input_result": INVALID_RESULT,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "meaning": "Sum of each minimum query answer plus the checksum offset, weighted by one-based query order.",
        "checksum_offset": CHECKSUM_OFFSET,
        "invalid_result": INVALID_RESULT,
    }
    require(workload.get("input") == expected_input, "input contract metadata mismatch")
    require(workload.get("output") == expected_output, "output contract metadata mismatch")
    require(workload.get("measurement") == {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": 9,
        "warmup_rounds": 1,
        "repetitions_per_sample": 20,
    }, "measurement metadata mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "workload cases must be an array")
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    require(len(ids) == len(cases) and len(set(ids)) == len(ids), "case IDs must be unique")
    require(set(ids) == CASE_IDS, "workload fixture set mismatch")
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
        expected = expected_result(values, input_is_null=is_null, input_length=input_length)
        require(expected == case["expected_result"], f"{case['id']}: oracle result mismatch")


def validate_sources() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "l" / f"li_chao_tree.{extension}"
        require(source.is_file(), f"missing {language} implementation")
        text = source.read_text(encoding="utf-8")
        require("li_chao_tree" in text, f"{language} implementation is missing its exported symbol")


def main() -> int:
    workload_path = ROOT / "benchmarks/l/li_chao_tree/workload.json"
    readme_path = ROOT / "benchmarks/l/li_chao_tree/README.md"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = readme_path.read_text(encoding="utf-8")
    for source in SOURCE_BASIS:
        require(source["url"] in readme, f"README is missing provenance URL: {source['title']}")
    print("li_chao_tree static contract, oracle fixtures, provenance, and nine source paths checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL li_chao_tree static verification: {error}", file=sys.stderr)
        raise SystemExit(1)
