"""Statically check the Segment Add Get Min workload and nine source ports."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from segment_add_get_min_oracle import (
    CHECKSUM_OFFSET,
    DOMAIN_HIGH,
    DOMAIN_LOW,
    DOMAIN_RIGHT,
    INFINITY_VALUE,
    MAX_INPUT_LENGTH,
    MAX_INITIAL_SEGMENTS,
    MAX_OPERATIONS,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "segment_add_get_min"
WORKLOAD_ID = "segment-add-get-min-bounded-domain-scalar-v1"
TASK_URL = "https://judge.yosupo.jp/problem/segment_add_get_min"
SPECIFICATION_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/segment_add_get_min/task.md"
SOURCE_FILES = (
    "c/s/segment_add_get_min.c",
    "c3/s/segment_add_get_min.c3",
    "cpp/s/segment_add_get_min.cpp",
    "elisa/s/segment_add_get_min.elisa",
    "nim/s/segment_add_get_min.nim",
    "odin/s/segment_add_get_min.odin",
    "rust/s/segment_add_get_min.rs",
    "v/s/segment_add_get_min.v",
    "zig/s/segment_add_get_min.zig",
)
CASE_IDS = {
    "empty-coverage-returns-infinity",
    "initial-segment-and-ordered-queries",
    "parallel-overlapping-lines-and-half-open-update",
    "range-update-changes-only-covered-subrange",
    "negative-coordinate-and-right-exclusive-boundary",
    "crossing-lines-in-shared-range",
    "updates-before-first-covered-query",
    "empty-trace",
    "update-before-query-with-no-initial-segments",
    "initial-count-above-bound",
    "operation-count-above-bound",
    "initial-left-endpoint-outside-domain",
    "empty-initial-interval",
    "initial-coefficient-out-of-range",
    "reversed-update-interval",
    "unknown-operation-code",
    "query-coordinate-outside-domain",
    "truncated-initial-segment",
    "truncated-add-operation",
    "truncated-query-operation",
    "trailing-value-after-operations",
    "null-input-pointer",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_case(case: Mapping[str, object]) -> None:
    values = case.get("input_values")
    require(isinstance(values, list), f"{case.get('id')}: input_values must be a list")
    require(len(values) <= MAX_INPUT_LENGTH, f"{case.get('id')}: input exceeds bound")
    require(
        all(type(value) is int and -(1 << 63) <= value < (1 << 63) for value in values),
        f"{case.get('id')}: values must be signed 64-bit integers",
    )
    input_length = case.get("input_length")
    require(
        type(input_length) is int and 0 <= input_length <= MAX_INPUT_LENGTH,
        f"{case.get('id')}: invalid input_length",
    )
    input_is_null = case.get("input_is_null", False)
    require(type(input_is_null) is bool, f"{case.get('id')}: invalid null-input flag")
    require(input_is_null == (case.get("id") == "null-input-pointer"),
            f"{case.get('id')}: unexpected null-input flag")
    require(input_length == (0 if input_is_null else len(values)),
            f"{case.get('id')}: declared input length differs from fixture")
    expected = expected_result(values, input_is_null=input_is_null, input_length=input_length)
    require(case.get("expected_result") == expected,
            f"{case.get('id')}: expected {expected}, got {case.get('expected_result')}")


def validate_workload(workload: object) -> None:
    require(isinstance(workload, Mapping), "workload root must be an object")
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi", "source",
        "contract", "input", "output", "workspace", "measurement", "cases",
    }, "workload top-level fields differ from the contract")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == WORKLOAD_ID, "workload id mismatch")
    require(workload.get("algorithm") == ALGORITHM, "algorithm name mismatch")
    require(workload.get("function_symbol") == ALGORITHM, "function symbol mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source") == {
        "repository": "Library Checker",
        "problem": "Segment Add Get Min",
        "url": TASK_URL,
        "specification_url": SPECIFICATION_URL,
        "source_type": "official_algorithm_task_specification",
        "reuse": "Task semantics and taxonomy only; no statement text or source code copied. The ports and direct-scan oracle are independently written.",
    }, "source provenance mismatch")
    require(workload.get("contract") == {
        "input_layout": "[N, Q, (l, r, a, b)*N, operation*Q]",
        "initial_segment": "Four signed 64-bit values (l, r, a, b) representing y=a*x+b for integer x in [l,r).",
        "add_operation": "Five values (0, l, r, a, b) add a segment over [l,r).",
        "query_operation": "Two values (1, p) query the minimum value at integer p.",
        "initial_segment_count_range": [0, MAX_INITIAL_SEGMENTS],
        "operation_count_range": [0, MAX_OPERATIONS],
        "coordinate_domain": [DOMAIN_LOW, DOMAIN_HIGH],
        "segment_endpoint_range": [DOMAIN_LOW, DOMAIN_RIGHT],
        "segment_interval_rule": "-32 <= l < r <= 32; the right endpoint is excluded.",
        "slope_and_intercept_range": [-1000, 1000],
        "empty_coverage_value": INFINITY_VALUE,
        "output_encoding": "Signed 64-bit scalar checksum: sum(q * (answer + 33001)) over queries in one-based query order, using the empty-coverage value when no segment covers p.",
        "invalid_input_result": -1,
    }, "bounded task contract mismatch")
    require(workload.get("input") == {
        "kind": "packed_signed_64_bit_integer_array",
        "maximum_valid_length": MAX_INPUT_LENGTH,
        "maximum_parseable_length": MAX_INPUT_LENGTH,
        "invalid_result": -1,
        "null_input_result": -1,
    }, "input metadata mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_integer",
        "meaning": "Position-weighted checksum of every query answer, with the documented sentinel for uncovered coordinates.",
        "checksum_offset": CHECKSUM_OFFSET,
        "empty_coverage_value": INFINITY_VALUE,
        "invalid_result": -1,
    }, "output metadata mismatch")
    require(workload.get("workspace") == {
        "bytes": 8192,
        "meaning": "Fixed implicit Li Chao segment tree over 64 integer coordinates.",
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
        require(isinstance(case, Mapping), "each fixture must be an object")
        validate_case(case)

    for relative in SOURCE_FILES:
        path = ROOT / relative
        require(path.is_file(), f"missing source port: {relative}")
        require(ALGORITHM in path.read_text(encoding="utf-8"),
                f"source port does not expose expected symbol: {relative}")

    readme_path = ROOT / "benchmarks" / "s" / ALGORITHM / "README.md"
    readme = readme_path.read_text(encoding="utf-8")
    require(TASK_URL in readme and SPECIFICATION_URL in readme,
            "README is missing official task provenance")
    require("O(log^2 U)" in readme and "O(log U)" in readme and "O(U)" in readme,
            "README is missing algorithm complexity")
    require("direct-scan oracle" in readme and "no statement text or source code" in readme,
            "README is missing independent oracle or clean-room provenance")
    require(all(relative in readme for relative in SOURCE_FILES),
            "README is missing one or more language links")


def main() -> int:
    workload_path = ROOT / "benchmarks" / "s" / ALGORITHM / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
