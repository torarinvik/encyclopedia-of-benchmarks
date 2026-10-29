#!/usr/bin/env python3
"""Statically check D'Esopo-Pape fixtures and all nine source paths."""

from __future__ import annotations

import json
from pathlib import Path
import sys

from d_esopo_pape_oracle import (
    INVALID_RESULT,
    MAX_EDGES,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_VERTICES,
    MAX_WEIGHT,
    OUTPUT_ERROR_RESULT,
    SOURCE_BASIS,
    expected_output,
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
    "single_vertex_empty",
    "directed_chain_and_unreachable",
    "nonzero_source",
    "reentered_vertex_moves_to_front",
    "zero_weight_loops_and_parallel_arcs",
    "source_component_disconnected_from_edges",
    "later_parallel_arc_improves_distance",
    "positive_self_loop_is_ignored",
    "maximum_vertex_output",
    "maximum_edge_count_and_input_length",
    "short_output_capacity",
    "null_output_pointer",
    "invalid_graph_precedes_output_error",
    "invalid_vertex_count",
    "invalid_edge_count",
    "invalid_source",
    "invalid_endpoint",
    "negative_weight",
    "weight_above_limit",
    "truncated_edge_record",
    "extra_payload",
    "null_input_pointer",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "d-esopo-pape-directed-shortest-paths-v1", "workload id mismatch")
    require(workload.get("algorithm") == "d_esopo_pape", "algorithm name mismatch")
    require(workload.get("function_symbol") == "d_esopo_pape", "function symbol mismatch")
    require(workload.get("source_basis") == SOURCE_BASIS, "source provenance metadata mismatch")
    require(workload.get("input") == {
        "kind": "packed_directed_weighted_edge_list",
        "encoding": "[n, m, source, (u, v, weight)...]",
        "vertex_count_range": [1, MAX_VERTICES],
        "edge_count_range": [0, MAX_EDGES],
        "weight_range": [0, MAX_WEIGHT],
        "maximum_valid_input_length": MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_INPUT_LENGTH,
        "vertex_numbering": "0 through n-1",
        "edge_records": "Directed; loops and parallel arcs are allowed.",
        "invalid_result": INVALID_RESULT,
        "null_input_result": INVALID_RESULT,
    }, "input contract metadata mismatch")
    require(workload.get("output") == {
        "kind": "little_endian_signed_i64_vector",
        "meaning": "One shortest-path distance per vertex in increasing vertex order; unreachable vertices encode as -1.",
        "invalid_result": INVALID_RESULT,
        "output_error_result": OUTPUT_ERROR_RESULT,
        "maximum_output_bytes": MAX_OUTPUT_BYTES,
    }, "output contract metadata mismatch")
    require(workload.get("measurement") == {
        "comparison_model": "i64_array_bytes_output",
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
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        output_capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        require(isinstance(values, list), f"{case['id']}: input_values must be an array")
        require(type(input_is_null) is bool, f"{case['id']}: input null flag must be boolean")
        require(type(output_is_null) is bool, f"{case['id']}: output null flag must be boolean")
        require(type(input_length) is int, f"{case['id']}: input length must be an integer")
        require(type(output_capacity) is int, f"{case['id']}: output capacity must be an integer")
        require(type(case.get("expected_result")) is int, f"{case['id']}: result must be an integer")
        require(isinstance(case.get("expected_output_hex"), str), f"{case['id']}: output hex must be a string")
        if input_is_null:
            require(case["id"] == "null_input_pointer" and values == [], "unexpected null-input fixture")
        else:
            require(input_length == len(values), f"{case['id']}: packed length mismatch")
        if case["id"] == "maximum_edge_count_and_input_length":
            require(input_length == MAX_INPUT_LENGTH and values[1] == MAX_EDGES,
                    "maximum edge/input case does not exercise its bound")
        result, payload = expected_output(
            values,
            input_is_null=input_is_null,
            input_length=input_length,
            output_is_null=output_is_null,
            output_capacity=output_capacity,
        )
        require(result == case["expected_result"], f"{case['id']}: Bellman-Ford result mismatch")
        require(payload.hex() == case["expected_output_hex"], f"{case['id']}: encoded output mismatch")


def validate_sources() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "d" / f"d_esopo_pape.{extension}"
        require(source.is_file(), f"missing {language} source")
        require("d_esopo_pape" in source.read_text(encoding="utf-8"),
                f"{language} source is missing its exported symbol")


def main() -> int:
    workload_path = ROOT / "benchmarks/d/d_esopo_pape/workload.json"
    readme_path = ROOT / "benchmarks/d/d_esopo_pape/README.md"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = readme_path.read_text(encoding="utf-8")
    for source in SOURCE_BASIS:
        require(source["url"] in readme, f"README is missing the citation for {source['organization']}")
    require("exponential" in readme.lower() and "no polynomial worst-case claim" in readme.lower(),
            "README must accurately state the lack of a polynomial worst-case bound")
    print("D'Esopo-Pape static contract, Bellman-Ford fixtures, and nine paths checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL D'Esopo-Pape static verification: {error}", file=sys.stderr)
        raise SystemExit(1)

