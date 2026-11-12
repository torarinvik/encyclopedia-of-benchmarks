#!/usr/bin/env python3
"""Statically verify the bounded static range LIS benchmark package."""

from __future__ import annotations

import json
from pathlib import Path

from static_range_lis_query_oracle import (
    MAX_N, MAX_Q, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES, expected_output as primary_expected_output,
)
from static_range_lis_query_verifier_oracle import expected_output as independent_expected_output

ROOT = Path(__file__).resolve().parents[1]
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_lis_query/task.md"
SOURCE_PATHS = (
    "c/s/static_range_lis_query.c", "c3/s/static_range_lis_query.c3",
    "cpp/s/static_range_lis_query.cpp", "elisa/s/static_range_lis_query.elisa",
    "mojo/s/static_range_lis_query.mojo", "nim/s/static_range_lis_query.nim",
    "odin/s/static_range_lis_query.odin", "rust/s/static_range_lis_query.rs",
    "v/s/static_range_lis_query.v", "zig/s/static_range_lis_query.zig",
)
CASE_IDS = {
    "multiple-subranges-and-empty-range", "decreasing-permutation",
    "short-output-capacity", "null-output", "duplicate-permutation-value",
    "invalid-range-order", "invalid-input-before-null-output", "overlong-frame",
}


def validate_workload(workload: object) -> None:
    if not isinstance(workload, dict):
        raise ValueError("workload root must be an object")
    if (set(workload) != {
            "schema_version", "id", "algorithm", "function_symbol", "abi",
            "description", "source", "input", "contract", "output",
            "workspace", "measurement", "cases"}
            or workload.get("schema_version") != 1
            or workload.get("id") != "library-checker-static-range-lis-query-bounded-v1"
            or workload.get("algorithm") != "static_range_lis_query"
            or workload.get("function_symbol") != "static_range_lis_query"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL):
        raise ValueError("static range LIS identity or source metadata mismatch")

    input_spec = workload["input"]
    if (input_spec != {
            "kind": "signed_64_bit_integer_array",
            "encoding": "[N,Q,permutation[N],(left,right)*Q]",
            "n_range": [1, MAX_N], "q_range": [1, MAX_Q],
            "permutation_values": "each integer in [0,N) exactly once",
            "query_rule": "0 <= left <= right <= N; intervals are half-open",
            "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
            "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
            "invalid_input_result": -1, "null_input_result": -1,
        }):
        raise ValueError("static range LIS input contract mismatch")
    if (workload.get("output") != {
            "kind": "little_endian_signed_64_bit_array",
            "encoding": "one strict LIS length per query, in query order",
            "element_width_bytes": 8, "maximum_elements": MAX_Q,
            "maximum_bytes": MAX_OUTPUT_BYTES,
            "success_result": "number of bytes written",
            "invalid_input_result": -1, "null_output_result": -2,
            "insufficient_capacity_result": -2, "no_write_on_error": True,
        }
            or workload.get("workspace") != {
                "bytes": MAX_WORKSPACE_BYTES,
                "meaning": "Permutation validation bitmap, one N-element tails array, staged query results, and local bookkeeping.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i64_array_bytes_output_call",
                "sample_count": 5, "warmup_rounds": 1, "repetitions_per_sample": 100,
            }):
        raise ValueError("static range LIS output, workspace, or measurement mismatch")
    contract = workload.get("contract", {})
    if (contract.get("empty_range_result") != 0
            or contract.get("invalid_input_result") != -1
            or contract.get("output_error_result") != -2
            or contract.get("no_write_on_error") is not True
            or "strictly increasing subsequence" not in contract.get("operation", "")
            or "lower-bound patience-sorting tails" not in contract.get("algorithm", "")):
        raise ValueError("static range LIS operation contract mismatch")

    cases = workload.get("cases")
    if (not isinstance(cases, list)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS
            or len(cases) != len(CASE_IDS)):
        raise ValueError("static range LIS fixture identifiers mismatch")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("static range LIS fixture must be an object")
        case_id = case["id"]
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        if (case_id in seen or set(case) - {
                "id", "input_values", "input_length", "output_capacity",
                "output_is_null", "input_is_null", "expected_result", "expected_output_hex"}
                or not {"id", "input_values", "input_length", "output_capacity",
                        "expected_result", "expected_output_hex"}.issubset(case)
                or not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(input_length) is not int or input_length != len(values)
                or input_length > MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool or type(input_is_null) is not bool):
            raise ValueError(f"static range LIS fixture framing mismatch: {case_id}")
        seen.add(case_id)
        primary = primary_expected_output(values, capacity, output_is_null,
                                          input_is_null, input_length)
        independent = independent_expected_output(values, capacity, output_is_null,
                                                  input_is_null, input_length)
        if primary != independent:
            raise ValueError(f"static range LIS oracles disagree: {case_id}")
        result, payload = independent
        if (case.get("expected_result") != result
                or case.get("expected_output_hex") != payload.hex()):
            raise ValueError(f"static range LIS fixture differs from its oracle: {case_id}")


def validate_sources() -> None:
    readme = (ROOT / "benchmarks/s/static_range_lis_query/README.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or "quadratic dynamic programming" not in readme:
        raise ValueError("static range LIS README is missing provenance or independent verifier notes")
    for relative in SOURCE_PATHS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"missing source file {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing the source link: {relative}")
        if "static_range_lis_query" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"source is missing the exported symbol: {relative}")


def main() -> int:
    package = ROOT / "benchmarks/s/static_range_lis_query"
    workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    return 0


if __name__ == "__main__":
    main()
