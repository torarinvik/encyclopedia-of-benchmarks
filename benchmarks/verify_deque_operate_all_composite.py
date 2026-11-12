#!/usr/bin/env python3
"""Static contract and fixture checker for the bounded deque benchmark."""

from __future__ import annotations

import json
from pathlib import Path

from deque_operate_all_composite_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OPERATIONS,
    MODULUS,
    TASK_URL,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATHS = (
    "c/d/deque_operate_all_composite.c",
    "c3/d/deque_operate_all_composite.c3",
    "cpp/d/deque_operate_all_composite.cpp",
    "elisa/d/deque_operate_all_composite.elisa",
    "nim/d/deque_operate_all_composite.nim",
    "odin/d/deque_operate_all_composite.odin",
    "rust/d/deque_operate_all_composite.rs",
    "v/d/deque_operate_all_composite.v",
    "zig/d/deque_operate_all_composite.zig",
)
CASE_IDS = {
    "zero-operations",
    "empty-deque-identity",
    "push-at-both-ends-order",
    "remove-from-both-ends",
    "invalid-empty-pop-front",
    "invalid-empty-pop-back",
    "invalid-zero-multiplier",
    "unknown-operation",
    "truncated-push",
    "trailing-value",
    "null-input",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi",
        "source", "contract", "input", "output", "workspace",
        "measurement", "cases",
    }, "workload fields differ from the bounded package schema")
    require(workload["schema_version"] == 1, "unsupported workload schema")
    require(workload["id"] == "library-checker-deque-operate-all-composite-bounded-scalar-v1",
            "workload id mismatch")
    require(workload["algorithm"] == "deque_operate_all_composite", "algorithm mismatch")
    require(workload["function_symbol"] == "deque_operate_all_composite", "symbol mismatch")
    require(workload["abi"] == "i64_array_scalar", "ABI mismatch")
    require(workload["source"] == {
        "repository": "Library Checker",
        "problem": "Deque Operate All Composite",
        "url": TASK_URL,
        "reuse": "Operation semantics and algorithm taxonomy only; local profile and implementations are clean-room.",
    }, "source provenance mismatch")
    require(workload["contract"] == {
        "input_layout": "[Q, operation*Q]",
        "push_front_operation": "Three values (0,a,b) prepend f(x)=a*x+b modulo 998244353.",
        "push_back_operation": "Three values (1,a,b) append f(x)=a*x+b modulo 998244353.",
        "pop_front_operation": "One value (2) removes the front function; invalid when empty.",
        "pop_back_operation": "One value (3) removes the back function; invalid when empty.",
        "query_operation": "Two values (4,x) apply the deque from front to back; an empty deque returns x.",
        "operation_count_range": [0, MAX_OPERATIONS],
        "multiplier_range": [1, MODULUS - 1],
        "intercept_and_argument_range": [0, MODULUS - 1],
        "modulus": MODULUS,
        "output_encoding": "Signed 64-bit checksum sum(query_ordinal * (answer + 1)) over queries in one-based query order.",
        "invalid_input_result": -1,
    }, "operation contract mismatch")
    require(workload["input"] == {
        "kind": "packed_signed_64_bit_integer_array",
        "maximum_valid_length": MAX_INPUT_LENGTH,
        "maximum_parseable_length": MAX_INPUT_LENGTH,
        "null_input_result": -1,
        "invalid_result": -1,
    }, "input bounds mismatch")
    require(workload["output"] == {
        "kind": "signed_64_bit_integer",
        "valid_result_range": [0, 2_076_348_254_240],
        "meaning": "Query-ordinal-weighted sum of each affine-composition answer plus one.",
        "invalid_result": -1,
    }, "output contract mismatch")
    require(workload["workspace"] == {
        "bytes": 4096,
        "meaning": "A fixed 256-node affine segment tree; endpoint indexes are scalar state.",
    }, "workspace contract mismatch")
    require(workload["measurement"] == {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": len(CASE_IDS),
        "warmup_rounds": 1,
        "repetitions_per_sample": 20,
    }, "measurement contract mismatch")

    cases = workload["cases"]
    require(isinstance(cases, list), "cases must be a list")
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    require(len(ids) == len(cases) and len(set(ids)) == len(ids), "case IDs must be unique")
    require(set(ids) == CASE_IDS, "fixture set mismatch")
    for case in cases:
        values = case["input_values"]
        require(type(case["input_length"]) is int and case["input_length"] == len(values),
                f"{case['id']}: input framing mismatch")
        require(len(values) <= MAX_INPUT_LENGTH, f"{case['id']}: input exceeds bound")
        result = expected_result(
            values,
            input_is_null=case.get("input_is_null", False),
            input_length=case["input_length"],
        )
        require(result == case["expected_result"], f"{case['id']}: expected result mismatch")

    all_front = [MAX_OPERATIONS, *(value for _ in range(MAX_OPERATIONS)
                                   for value in (0, 1, 0))]
    all_back = [MAX_OPERATIONS, *(value for _ in range(MAX_OPERATIONS)
                                  for value in (1, 1, 0))]
    require(len(all_front) == MAX_INPUT_LENGTH and expected_result(all_front) == 0,
            "maximum-size front-insertion trace differs from its contract")
    require(len(all_back) == MAX_INPUT_LENGTH and expected_result(all_back) == 0,
            "maximum-size back-insertion trace differs from its contract")


def validate_sources() -> None:
    for relative in SOURCE_PATHS:
        source = ROOT / relative
        require(source.is_file(), f"missing source file {relative}")
        require("deque_operate_all_composite" in source.read_text(encoding="utf-8"),
                f"source is missing the exported symbol: {relative}")


def validate_readme() -> None:
    readme = (ROOT / "benchmarks/d/deque_operate_all_composite/README.md").read_text(
        encoding="utf-8")
    require(TASK_URL in readme, "README is missing official task provenance")
    require("segment tree" in readme and "O(log Q)" in readme,
            "README is missing the algorithm and complexity")
    for relative in SOURCE_PATHS:
        require(relative in readme, f"README is missing source link {relative}")


if __name__ == "__main__":
    package = ROOT / "benchmarks/d/deque_operate_all_composite"
    validate_workload(json.loads((package / "workload.json").read_text(encoding="utf-8")))
    validate_sources()
    validate_readme()
