#!/usr/bin/env python3
"""Statically check the incremental-SCC workload, oracle, and source paths."""

from __future__ import annotations

import json
from pathlib import Path
import sys

from incremental_scc_oracle import (
    INVALID_RESULT,
    MAX_EDGES,
    MAX_INPUT_LENGTH,
    MAX_VERTICES,
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
    "one_vertex_no_arcs",
    "isolated_vertices_no_arcs",
    "single_forward_arc",
    "cycle_closes_on_second_arc",
    "self_loops_do_not_merge_vertices",
    "parallel_arcs_then_reverse_arc",
    "cycle_with_one_outgoing_tail",
    "two_cycles_merge_after_bridge_back",
    "eight_vertex_cycle_max_vertices",
    "thirty_two_loop_insertions_max_edges",
    "invalid_zero_vertices",
    "invalid_vertex_limit",
    "invalid_negative_edge_count",
    "invalid_edge_limit",
    "endpoint_out_of_range",
    "truncated_edge_record",
    "extra_payload",
    "null_input_pointer_with_positive_length",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "incremental-scc-prefix-checksum-v1", "workload id mismatch")
    require(workload.get("algorithm") == "incremental_scc", "algorithm name mismatch")
    require(workload.get("function_symbol") == "incremental_scc", "function symbol mismatch")
    require(workload.get("source_basis") == SOURCE_BASIS, "source provenance metadata mismatch")
    require(workload.get("input") == {
        "kind": "packed_insertion_only_directed_multigraph_edge_list",
        "encoding": "[n, m, (u, v)...]",
        "vertex_count_range": [1, MAX_VERTICES],
        "edge_count_range": [0, MAX_EDGES],
        "maximum_valid_input_length": MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_INPUT_LENGTH,
        "vertex_numbering": "0 through n-1",
        "edge_semantics": "Each edge record inserts one directed arc; loops and parallel arcs are allowed.",
        "invalid_result": INVALID_RESULT,
        "null_input_result": INVALID_RESULT,
    }, "input contract metadata mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_integer",
        "meaning": "Sum over one-based insertion steps of step times the SCC count after that insertion.",
        "empty_sequence_result": 0,
        "invalid_result": INVALID_RESULT,
    }, "output contract metadata mismatch")
    require(workload.get("algorithm_contract") == {
        "closure_update": "Before inserting u->v, snapshot all x reaching u and all y reachable from v; add every pair x reaches y.",
        "scc_relation": "Vertices are in the same component iff each reaches the other.",
        "time_complexity": "O(m*n^2)",
        "space_complexity": "O(n^2+m)",
    }, "algorithm contract metadata mismatch")
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
    require(set(ids) == CASE_IDS, "fixture set mismatch")
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
        require(
            expected_result(values, input_is_null=is_null, input_length=input_length) == case["expected_result"],
            f"{case['id']}: prefix-recomputation oracle mismatch",
        )


def validate_sources() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "i" / f"incremental_scc.{extension}"
        require(source.is_file(), f"missing {language} source")
        require("incremental_scc" in source.read_text(encoding="utf-8"),
                f"{language} source is missing its exported symbol")


def main() -> int:
    package = ROOT / "benchmarks/i/incremental_scc"
    workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = (package / "README.md").read_text(encoding="utf-8")
    for source in SOURCE_BASIS:
        require(source["url"] in readme, f"README is missing provenance URL: {source['url']}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL incremental_scc static verification: {error}", file=sys.stderr)
        raise SystemExit(1)
