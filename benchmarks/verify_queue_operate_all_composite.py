"""Static workload and ten-port validator for affine aggregate queues."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from queue_operate_all_composite_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OPERATIONS,
    MODULUS,
    PROPOSAL_URL,
    TASK_URL,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "queue_operate_all_composite"
WORKLOAD_ID = "queue-operate-all-affine-composite-bounded-scalar-v1"
SOURCE_FILES = (
    "c/q/queue_operate_all_composite.c",
    "c3/q/queue_operate_all_composite.c3",
    "cpp/q/queue_operate_all_composite.cpp",
    "elisa/q/queue_operate_all_composite.elisa",
    "mojo/q/queue_operate_all_composite.mojo",
    "nim/q/queue_operate_all_composite.nim",
    "odin/q/queue_operate_all_composite.odin",
    "rust/q/queue_operate_all_composite.rs",
    "v/q/queue_operate_all_composite.v",
    "zig/q/queue_operate_all_composite.zig",
)
CASE_IDS = {
    "zero-operations", "empty-queue-identity", "single-affine-function",
    "ordered-composition", "fifo-removal", "refill-after-complete-transfer",
    "weighted-multiple-queries",
    "modular-boundary", "invalid-pop-from-empty", "invalid-zero-multiplier",
    "unknown-operation", "truncated-push", "trailing-value", "null-input-pointer",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_sources() -> None:
    for relative in SOURCE_FILES:
        path = ROOT / relative
        require(path.is_file(), f"missing implementation: {relative}")
        require(ALGORITHM in path.read_text(encoding="utf-8"),
                f"implementation does not expose the expected symbol: {relative}")


def validate_case(case: Mapping[str, object]) -> None:
    identifier = case.get("id")
    values = case.get("input_values")
    require(isinstance(values, list), f"{identifier}: input_values must be an array")
    require(len(values) <= MAX_INPUT_LENGTH, f"{identifier}: input exceeds the parser bound")
    require(all(type(value) is int and -(1 << 63) <= value < (1 << 63) for value in values),
            f"{identifier}: input values must be signed 64-bit integers")
    null_input = case.get("input_is_null", False)
    input_length = case.get("input_length")
    require(type(null_input) is bool, f"{identifier}: invalid null-input flag")
    require(type(input_length) is int and 0 <= input_length <= MAX_INPUT_LENGTH,
            f"{identifier}: invalid declared input length")
    require(null_input == (identifier == "null-input-pointer"),
            f"{identifier}: null-input flag does not match fixture type")
    require(input_length == (0 if null_input else len(values)),
            f"{identifier}: declared input length differs from the fixture")
    result = expected_result(values, input_is_null=null_input, input_length=input_length)
    require(type(case.get("expected_result")) is int and case.get("expected_result") == result,
            f"{identifier}: expected_result differs from the direct-list oracle")


def validate_workload(workload: object) -> None:
    require(isinstance(workload, Mapping), "workload root must be an object")
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi", "source",
        "contract", "input", "output", "workspace", "measurement", "cases",
    }, "workload fields differ from the reviewed contract")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == WORKLOAD_ID, "workload ID mismatch")
    require(workload.get("algorithm") == ALGORITHM, "algorithm name mismatch")
    require(workload.get("function_symbol") == ALGORITHM, "exported symbol mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source") == {
        "repository": "Library Checker",
        "problem": "Queue Operate All Composite",
        "url": TASK_URL,
        "proposal_url": PROPOSAL_URL,
        "source_type": "official_task_and_proposal_semantics",
        "reuse": "Operation semantics and algorithm taxonomy only; the bounded profile, implementations, workload, and direct-list oracle are independently written. No task statement text or submitted source code was copied.",
    }, "source provenance differs from the reviewed task taxonomy")
    require(workload.get("contract") == {
        "input_layout": "[Q, operation*Q]",
        "push_operation": "Three values (0,a,b) append f(x)=a*x+b modulo 998244353.",
        "pop_operation": "One value (1) removes the oldest function and is invalid when the queue is empty.",
        "query_operation": "Two values (2,x) apply queued functions from oldest to newest; an empty queue returns x.",
        "operation_count_range": [0, MAX_OPERATIONS],
        "multiplier_range": [1, MODULUS - 1],
        "intercept_and_argument_range": [0, MODULUS - 1],
        "modulus": MODULUS,
        "output_encoding": "Signed 64-bit checksum sum(q * (answer + 1)) over queries in one-based query order.",
        "invalid_input_result": -1,
    }, "operation contract differs from the bounded profile")
    require(workload.get("input") == {
        "kind": "packed_signed_64_bit_integer_array",
        "maximum_valid_length": MAX_INPUT_LENGTH,
        "maximum_parseable_length": MAX_INPUT_LENGTH,
        "null_input_result": -1,
        "invalid_result": -1,
    }, "input framing metadata mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_integer",
        "valid_result_range": [0, MAX_OPERATIONS * (MAX_OPERATIONS + 1) // 2 * MODULUS],
        "meaning": "One-based query-ordinal-weighted sum of each affine-composition answer plus one.",
        "invalid_result": -1,
    }, "output metadata mismatch")
    require(workload.get("workspace") == {
        "bytes": 3072,
        "meaning": "Two fixed stacks with affine values and aggregate values, each sized for 64 operations.",
    }, "workspace metadata mismatch")
    require(workload.get("measurement") == {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": 9,
        "warmup_rounds": 1,
        "repetitions_per_sample": 20,
    }, "measurement metadata mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "workload cases must be an array")
    identifiers = [case.get("id") for case in cases if isinstance(case, Mapping)]
    require(len(identifiers) == len(cases) and len(set(identifiers)) == len(identifiers),
            "fixture IDs must be unique")
    require(set(identifiers) == CASE_IDS, "fixture set differs from the expected cases")
    for case in cases:
        require(isinstance(case, Mapping), "every fixture must be an object")
        validate_case(case)

    validate_sources()
    readme = (ROOT / "benchmarks" / "q" / ALGORITHM / "README.md").read_text(encoding="utf-8")
    require(TASK_URL in readme and PROPOSAL_URL in readme,
            "README is missing task or proposal provenance")
    require("O(1) amortized" in readme and "direct-list oracle" in readme,
            "README is missing complexity or oracle documentation")
    require(all(relative in readme for relative in SOURCE_FILES),
            "README is missing one or more language links")

    maximum = [MAX_OPERATIONS]
    for _ in range(MAX_OPERATIONS):
        maximum.extend((0, 1, 0))
    require(len(maximum) == MAX_INPUT_LENGTH, "maximum trace framing differs from parser bound")
    require(expected_result(maximum) == 0, "maximum trace checksum changed unexpectedly")
    require(expected_result([0] * (MAX_INPUT_LENGTH + 1)) == -1,
            "oracle accepted input above the parser bound")


def main() -> int:
    workload_path = ROOT / "benchmarks" / "q" / ALGORITHM / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
