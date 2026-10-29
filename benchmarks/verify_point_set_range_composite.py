"""Static workload and nine-port validator for point-set range composition."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from point_set_range_composite_oracle import (
    MAX_INPUT_LENGTH,
    MAX_N,
    MAX_OPERATIONS,
    MODULUS,
    PROPOSAL_URL,
    TASK_URL,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "point_set_range_composite"
WORKLOAD_ID = "point-set-range-affine-composite-bounded-scalar-v1"
SOURCE_FILES = (
    "c/p/point_set_range_composite.c",
    "c3/p/point_set_range_composite.c3",
    "cpp/p/point_set_range_composite.cpp",
    "elisa/p/point_set_range_composite.elisa",
    "nim/p/point_set_range_composite.nim",
    "odin/p/point_set_range_composite.odin",
    "rust/p/point_set_range_composite.rs",
    "v/p/point_set_range_composite.v",
    "zig/p/point_set_range_composite.zig",
)
CASE_IDS = {
    "identity-single-query",
    "single-affine-map",
    "ordered-full-range-composition",
    "composition-order-at-one",
    "point-replacement-before-query",
    "weighted-query-order",
    "empty-range-is-identity",
    "modular-result-reduction",
    "non-power-of-two-partial-range",
    "interleaved-point-updates-and-queries",
    "zero-operations",
    "maximum-array-and-query-count",
    "invalid-zero-length-array",
    "invalid-operation-count",
    "invalid-initial-coefficient",
    "invalid-update-coefficient",
    "unknown-opcode",
    "reversed-query-interval",
    "truncated-operation",
    "trailing-value",
    "null-input-pointer",
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
            f"{identifier}: expected_result differs from the direct-scan oracle")


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
        "problem": "Point Set Range Composite (Linear Functions)",
        "url": TASK_URL,
        "proposal_url": PROPOSAL_URL,
        "source_type": "official_task_and_proposal_semantics",
        "reuse": "Task operation order and affine-map semantics only; the bounded profile, implementations, workload, and direct-scan oracle are independently written. No task statement text or submitted source code was copied.",
    }, "source provenance differs from the reviewed task taxonomy")
    require(workload.get("contract") == {
        "input_layout": "[N, Q, (a, b)*N, operation*Q]",
        "initial_map": "Each pair (a,b) denotes f(x)=a*x+b modulo 998244353.",
        "point_set_operation": "Four values (0,p,c,d) replace f_p with x -> c*x+d modulo 998244353.",
        "range_query_operation": "Four values (1,l,r,x) apply f_l, f_(l+1), ..., f_(r-1) in that order to x; equivalently return f_(r-1)(...f_l(x)...). The interval [l,r) may be empty.",
        "array_length_range": [1, MAX_N],
        "operation_count_range": [0, MAX_OPERATIONS],
        "coefficient_and_argument_range": [0, MODULUS - 1],
        "modulus": MODULUS,
        "output_encoding": "Signed 64-bit scalar checksum sum(q * answer_q) modulo 998244353, with one-based query ordinal q.",
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
        "valid_result_range": [0, MODULUS - 1],
        "meaning": "One-based query-ordinal-weighted sum of range-composition results modulo 998244353.",
        "invalid_result": -1,
    }, "output metadata mismatch")
    require(workload.get("workspace") == {
        "bytes": 1024,
        "meaning": "Fixed iterative power-of-two segment tree with 64 affine-map nodes.",
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
    readme_path = ROOT / "benchmarks" / "p" / ALGORITHM / "README.md"
    readme = readme_path.read_text(encoding="utf-8")
    require(TASK_URL in readme and PROPOSAL_URL in readme,
            "README is missing task or proposal provenance")
    require("O(log N)" in readme and "O(N)" in readme and "direct-scan oracle" in readme,
            "README is missing complexity or oracle documentation")
    require("same algorithm family" in readme and "no duplicate large-array package" in readme,
            "README is missing canonical-profile clarification")
    require(all(relative in readme for relative in SOURCE_FILES),
            "README is missing one or more language links")

    maximum = [MAX_N, MAX_OPERATIONS]
    for _ in range(MAX_N):
        maximum.extend((1, 0))
    for _ in range(MAX_OPERATIONS):
        maximum.extend((1, 0, 0, 0))
    require(len(maximum) == MAX_INPUT_LENGTH, "maximum trace framing does not match the parser bound")
    require(expected_result(maximum) == 0, "maximum identity-map trace changed unexpectedly")
    require(expected_result([0] * (MAX_INPUT_LENGTH + 1)) == -1,
            "oracle accepted input above the parser bound")


def main() -> int:
    workload_path = ROOT / "benchmarks" / "p" / ALGORITHM / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
