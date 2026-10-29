"""Static workload, fixture, provenance, and source checks for the directed task."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from counting_spanning_trees_directed_oracle import (
    MAX_INPUT_LENGTH,
    OUTPUT_BYTES,
    expected_output,
)

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "counting_spanning_trees_directed"
WORKLOAD_ID = "counting-spanning-trees-directed-matrix-tree-i64-array-bytes-output-v1"
SOURCE_FILES = (
    "c/c/counting_spanning_trees_directed.c",
    "c3/c/counting_spanning_trees_directed.c3",
    "cpp/c/counting_spanning_trees_directed.cpp",
    "elisa/c/counting_spanning_trees_directed.elisa",
    "nim/c/counting_spanning_trees_directed.nim",
    "odin/c/counting_spanning_trees_directed.odin",
    "rust/c/counting_spanning_trees_directed.rs",
    "v/c/counting_spanning_trees_directed.v",
    "zig/c/counting_spanning_trees_directed.zig",
)
EXPECTED_CASE_IDS = {
    "singleton-with-loops", "outward-path", "complete-bidirected-three",
    "parallel-arcs-chain", "loop-does-not-contribute", "disconnected-root",
    "maximum-parallel-arc-bound", "vertex-count-out-of-range",
    "edge-count-out-of-range", "root-out-of-range", "endpoint-out-of-range",
    "truncated-edge-frame", "invalid-before-output-error", "short-output-capacity",
    "null-output", "null-input",
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
    if case.get("expected_result") != result or case.get("expected_output_hex") != output.hex():
        raise AssertionError(
            f"{case.get('id')}: oracle produced ({result}, {output.hex()}), "
            f"expected ({case.get('expected_result')}, {case.get('expected_output_hex')})"
        )


def verify_workload(workload: Mapping[str, object]) -> None:
    cases = workload.get("cases")
    source = workload.get("source")
    contract = workload.get("contract")
    input_spec = workload.get("input")
    output_spec = workload.get("output")
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
        or not isinstance(source, Mapping)
        or source.get("repository") != "Library Checker"
        or source.get("problem") != "Counting Spanning Trees (Directed)"
        or source.get("url") != "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_spanning_tree_directed/task.md"
        or not isinstance(contract, Mapping)
        or contract.get("input_layout") != "[n, m, r, (u, v)*m]"
        or contract.get("vertex_count_range") != [1, 6]
        or contract.get("edge_count_range") != [0, 12]
        or contract.get("modulus") != 998_244_353
        or "directed Matrix-Tree theorem" not in str(contract.get("algorithm"))
        or contract.get("parallel_edges") != "Each input arc is distinct and contributes separately."
        or contract.get("self_loops") != "Accepted but cannot belong to an outward spanning arborescence."
        or contract.get("no_write_on_error") is not True
        or not isinstance(input_spec, Mapping)
        or input_spec.get("maximum_valid_length") != MAX_INPUT_LENGTH
        or input_spec.get("maximum_parseable_length") != MAX_INPUT_LENGTH
        or not isinstance(output_spec, Mapping)
        or output_spec.get("maximum_bytes") != OUTPUT_BYTES
        or not isinstance(cases, list)
        or {case.get("id") for case in cases if isinstance(case, Mapping)} != EXPECTED_CASE_IDS
        or len(cases) != len(EXPECTED_CASE_IDS)
    ):
        raise ValueError("workload metadata or fixture IDs differ from the bounded directed contract")

    for case in cases:
        if not isinstance(case, Mapping):
            raise ValueError("each fixture must be an object")
        verify_case(case)

    for relative in SOURCE_FILES:
        path = ROOT / relative
        if not path.is_file() or ALGORITHM not in path.read_text(encoding="utf-8"):
            raise ValueError(f"missing language port or exported symbol: {relative}")

    readme = (ROOT / "benchmarks" / "c" / ALGORITHM / "README.md").read_text(encoding="utf-8")
    if (
        "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_spanning_tree_directed/task.md" not in readme
        or "directed Matrix-Tree theorem" not in readme
        or "O(n^3 + m)" not in readme
        or "O(n^2)" not in readme
        or "edge-subset enumeration" not in readme
        or any(relative not in readme for relative in SOURCE_FILES)
    ):
        raise ValueError("README is missing provenance, complexity, oracle, or source links")


def main() -> int:
    workload_path = ROOT / "benchmarks" / "c" / ALGORITHM / "workload.json"
    verify_workload(json.loads(workload_path.read_text(encoding="utf-8")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
