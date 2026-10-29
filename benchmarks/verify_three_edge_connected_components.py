#!/usr/bin/env python3
"""Statically check the three-edge-connected component fixtures and ports."""

from __future__ import annotations

import json
from pathlib import Path
import sys

from three_edge_connected_components_oracle import (
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
    "single_isolated_vertex",
    "two_isolated_vertices",
    "single_bridge",
    "two_parallel_edges",
    "three_parallel_edges_are_independent_ids",
    "triangle_is_only_two_edge_connected",
    "complete_four_vertex_graph",
    "complete_graph_missing_one_edge",
    "loop_only_edges_do_not_join_vertices",
    "three_parallel_edges_with_loops",
    "two_disjoint_complete_four_vertex_graphs",
    "invalid_zero_vertices",
    "invalid_edge_count",
    "endpoint_outside_graph",
    "malformed_edge_record",
    "null_input_pointer_with_positive_length",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "three-edge-connected-components-canonical-v1", "workload id mismatch")
    require(workload.get("algorithm") == "three_edge_connected_components", "algorithm name mismatch")
    require(workload.get("function_symbol") == "three_edge_connected_components", "function symbol mismatch")
    require(workload.get("source_basis") == SOURCE_BASIS, "source provenance metadata mismatch")
    require(workload.get("input") == {
        "kind": "packed_undirected_multigraph_edge_list",
        "encoding": "[n, m, (u, v)...]",
        "vertex_count_range": [1, MAX_VERTICES],
        "edge_count_range": [0, MAX_EDGES],
        "maximum_valid_input_length": MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_INPUT_LENGTH,
        "vertex_numbering": "0 through n-1",
        "edge_ids": "Each edge record position is a distinct edge ID; loops and parallel edges are allowed.",
        "invalid_result": INVALID_RESULT,
        "null_input_result": INVALID_RESULT,
    }, "input contract metadata mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_integer",
        "meaning": "Base-8 digits of canonical component labels: label[v] is the digit at place 8^v.",
        "component_relation": "Vertices share a component iff connected after every removal of zero, one, or two edge IDs.",
        "canonical_order": "Components are numbered by ascending smallest vertex.",
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
        result = expected_result(values, input_is_null=is_null, input_length=input_length)
        require(result == case["expected_result"], f"{case['id']}: edge-removal oracle mismatch")


def validate_sources() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "t" / f"three_edge_connected_components.{extension}"
        require(source.is_file(), f"missing {language} source")
        require("three_edge_connected_components" in source.read_text(encoding="utf-8"),
                f"{language} source is missing its exported symbol")


def main() -> int:
    workload_path = ROOT / "benchmarks/t/three_edge_connected_components/workload.json"
    readme_path = ROOT / "benchmarks/t/three_edge_connected_components/README.md"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = readme_path.read_text(encoding="utf-8")
    require(SOURCE_BASIS["url"] in readme, "README is missing the Library Checker URL")
    print("three-edge-connected components static contract, edge-removal oracle, and nine paths checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL three_edge_connected_components static verification: {error}", file=sys.stderr)
        raise SystemExit(1)
