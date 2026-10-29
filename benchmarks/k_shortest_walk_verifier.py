"""Static workload, fixture, provenance, and source checks for k_shortest_walk."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from k_shortest_walk_oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "k_shortest_walk"
WORKLOAD_ID = "k-shortest-walk-bounded-i64-array-bytes-output-v1"
TASK_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/k_shortest_walk/task.md"
SOURCE_FILES = (
    "c/k/k_shortest_walk.c",
    "c3/k/k_shortest_walk.c3",
    "cpp/k/k_shortest_walk.cpp",
    "elisa/k/k_shortest_walk.elisa",
    "nim/k/k_shortest_walk.nim",
    "odin/k/k_shortest_walk.odin",
    "rust/k/k_shortest_walk.rs",
    "v/k/k_shortest_walk.v",
    "zig/k/k_shortest_walk.zig",
)
EXPECTED_CASE_IDS = {
    "parallel-arc-walks", "three-equal-cost-routes-with-shortfall",
    "zero-cost-loop-generates-repeated-walks", "zero-cost-singleton-loop",
    "unreachable-target", "source-equals-target-without-cycle",
    "finite-routes-fill-with-minus-one", "maximum-output-vector",
    "vertex-count-out-of-range", "edge-count-out-of-range", "k-out-of-range",
    "source-out-of-range", "target-out-of-range", "endpoint-out-of-range",
    "negative-weight", "weight-above-bound", "truncated-edge-frame",
    "trailing-input-value", "invalid-input-precedes-output-error",
    "short-output-capacity", "null-output", "null-input",
}


def verify_case(case: Mapping[str, object]) -> None:
    values = case.get("input_values")
    if not isinstance(values, list):
        raise ValueError("case input_values must be an array")
    result, output = expected_output(
        values,
        capacity=case.get("output_capacity"),
        output_is_null=case.get("output_is_null", False),
        input_is_null=case.get("input_is_null", False),
        input_length=case.get("input_length"),
    )
    if (case.get("expected_result") != result
            or case.get("expected_output_hex") != output.hex()):
        raise AssertionError(
            f"{case.get('id')}: oracle produced ({result}, {output.hex()}), "
            f"expected ({case.get('expected_result')}, {case.get('expected_output_hex')})"
        )


def verify_workload(workload: Mapping[str, object]) -> None:
    source = workload.get("source")
    contract = workload.get("contract")
    input_spec = workload.get("input")
    output_spec = workload.get("output")
    workspace = workload.get("workspace")
    cases = workload.get("cases")
    expected_source = {
        "repository": "Library Checker",
        "problem": "K Shortest Walk",
        "url": "https://judge.yosupo.jp/problem/k_shortest_walk",
        "specification_url": TASK_URL,
        "source_type": "official_algorithm_task_specification",
        "reuse": "Task definition and taxonomy only; no statement text or source code copied. Implementations and oracle are independently written.",
    }
    expected_contract = {
        "operation": "Return the k shortest directed walk lengths from s to t, counting edge-distinct walks separately.",
        "input_layout": "[n, m, s, t, k, (u, v, w)*m]",
        "vertex_count_range": [1, 6],
        "edge_count_range": [0, 12],
        "k_range": [1, 8],
        "vertex_ids": "zero-based",
        "weight_range": [0, 1000],
        "graph_semantics": "Directed multigraph; parallel arcs are distinct and may be reused.",
        "walk_semantics": "Vertices and edges may repeat; the zero-edge walk from s to s has length zero.",
        "exact_input_length": "5 + 3*m",
        "output_encoding": "k signed 64-bit distances in little-endian order; missing ranks are -1",
        "success_result": "8*k bytes written",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_output_capacity_result": -2,
        "no_write_on_error": True,
        "error_precedence": "Input framing and graph validation precede output pointer and capacity checks.",
    }
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "maximum_valid_length": MAX_INPUT_LENGTH,
        "maximum_parseable_length": MAX_INPUT_LENGTH,
        "invalid_result": -1,
        "null_input_result": -1,
    }
    expected_output = {
        "kind": "little_endian_signed_64_bit_vector",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "8*k bytes",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_output_capacity_result": -2,
        "no_write_on_error": True,
    }
    expected_workspace = {
        "bytes": 8192,
        "meaning": "Bounded edge arrays, per-vertex expansion counts, sorted walk frontier, and output scratch.",
    }
    if (
        set(workload) != {
            "schema_version", "id", "algorithm", "function_symbol", "abi", "source",
            "contract", "input", "output", "workspace", "measurement", "cases",
        }
        or workload.get("schema_version") != 1
        or workload.get("id") != WORKLOAD_ID
        or workload.get("algorithm") != ALGORITHM
        or workload.get("function_symbol") != ALGORITHM
        or workload.get("abi") != "i64_array_bytes_output"
        or source != expected_source
        or contract != expected_contract
        or input_spec != expected_input
        or output_spec != expected_output
        or workspace != expected_workspace
        or workload.get("measurement") != {
            "comparison_model": "i64_array_bytes_output_call",
            "sample_count": 5,
            "warmup_rounds": 1,
            "repetitions_per_sample": 100,
        }
        or not isinstance(cases, list)
        or {case.get("id") for case in cases if isinstance(case, Mapping)} != EXPECTED_CASE_IDS
        or len(cases) != len(EXPECTED_CASE_IDS)
    ):
        raise ValueError("workload metadata or fixtures differ from the bounded contract")

    for case in cases:
        if not isinstance(case, Mapping):
            raise ValueError("each fixture must be an object")
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or (input_is_null and (values or output_is_null))
                or (not input_is_null and input_length != len(values))):
            raise ValueError(f"invalid fixture framing: {case.get('id')}")
        verify_case(case)

    for relative in SOURCE_FILES:
        path = ROOT / relative
        if not path.is_file() or ALGORITHM not in path.read_text(encoding="utf-8"):
            raise ValueError(f"missing language port or exported symbol: {relative}")

    readme = (ROOT / "benchmarks" / "k" / ALGORITHM / "README.md").read_text(encoding="utf-8")
    if (TASK_URL not in readme
            or "https://judge.yosupo.jp/problem/k_shortest_walk" not in readme
            or "O((KM)^2 + K*N + M)" not in readme
            or "dynamic programming by exact" not in readme
            or "walk edge count" not in readme
            or "no statement text or source code" not in readme
            or any(relative not in readme for relative in SOURCE_FILES)):
        raise ValueError("README is missing provenance, complexity, oracle, or nine port links")


def main() -> int:
    workload_path = ROOT / "benchmarks" / "k" / ALGORITHM / "workload.json"
    verify_workload(json.loads(workload_path.read_text(encoding="utf-8")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
