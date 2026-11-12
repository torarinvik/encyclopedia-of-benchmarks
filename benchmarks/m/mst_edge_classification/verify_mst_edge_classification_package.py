"""Static package inventory and fixture/oracle consistency checker."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
BENCHMARKS = PACKAGE.parents[1]
ROOT = PACKAGE.parents[2]
ALGORITHM = "mst_edge_classification"
KRUSKAL_URL = "https://cp-algorithms.com/graph/mst_kruskal.html"
BRIDGE_URL = "https://cp-algorithms.com/graph/bridge-searching.html"
PORTS = (
    "c/m/mst_edge_classification.c",
    "c3/m/mst_edge_classification.c3",
    "cpp/m/mst_edge_classification.cpp",
    "elisa/m/mst_edge_classification.elisa",
    "mojo/m/mst_edge_classification.mojo",
    "nim/m/mst_edge_classification.nim",
    "odin/m/mst_edge_classification.odin",
    "rust/m/mst_edge_classification.rs",
    "v/m/mst_edge_classification.v",
    "zig/m/mst_edge_classification.zig",
)
CASE_IDS = {
    "unique-weight-path-edges-are-critical",
    "equal-weight-triangle-edges-are-pseudo-critical",
    "heavier-cycle-edge-is-in-no-mst",
    "contracted-parallel-edges-keep-separate-edge-ids",
    "one-vertex-empty-tree",
    "maximum-vertex-bound-path",
    "maximum-edge-bound-equal-weight-graph",
    "disconnected-graph-is-invalid",
    "duplicate-undirected-pair-is-invalid",
    "self-loop-is-invalid",
    "weight-above-bound-is-invalid",
    "trailing-input-word-is-invalid",
    "short-output-buffer",
    "null-output-buffer",
    "null-input",
}


def _load_oracle(filename: str):
    path = BENCHMARKS / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_package() -> None:
    primary = _load_oracle("mst_edge_classification_oracle.py")
    independent = _load_oracle("mst_edge_classification_exhaustive_oracle.py")
    expected_bounds = (12, 24, 74, 75, 24)
    for oracle in (primary, independent):
        actual_bounds = (
            oracle.MAX_VERTICES,
            oracle.MAX_EDGES,
            oracle.MAX_VALID_INPUT_LENGTH,
            oracle.MAX_PARSEABLE_INPUT_LENGTH,
            oracle.MAX_OUTPUT_BYTES,
        )
        if actual_bounds != expected_bounds:
            raise ValueError("oracle bounds differ from the package contract")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    source_spec = workload.get("source", {})
    if (
        workload.get("algorithm") != ALGORITHM
        or workload.get("function_symbol") != ALGORITHM
        or workload.get("abi") != "i64_array_bytes_output"
        or source_spec.get("url") != KRUSKAL_URL
        or source_spec.get("related_algorithm_url") != BRIDGE_URL
        or input_spec.get("vertex_count_range") != [1, 12]
        or input_spec.get("edge_count_range") != [0, 24]
        or input_spec.get("maximum_valid_input_length") != 74
        or input_spec.get("maximum_parseable_input_length") != 75
        or input_spec.get("connected_graph_required") is not True
        or output_spec.get("maximum_bytes") != 24
        or workload.get("workspace", {}).get("bytes") != 24
        or workload.get("measurement", {}).get("comparison_model")
        != "i64_array_bytes_output_call"
    ):
        raise ValueError("workload metadata differs from the bounded ABI contract")

    cases = workload.get("cases")
    if (
        not isinstance(cases, list)
        or len(cases) != len(CASE_IDS)
        or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS
    ):
        raise ValueError("workload fixtures are missing or have duplicate identifiers")
    allowed_fields = {
        "id", "input_values", "input_length", "output_capacity",
        "input_is_null", "output_is_null", "expected_result", "expected_output_bytes",
    }
    required_fields = {
        "id", "input_values", "input_length", "output_capacity",
        "expected_result", "expected_output_bytes",
    }
    for case in cases:
        if (
            not isinstance(case, dict)
            or set(case) - allowed_fields
            or not required_fields.issubset(case)
        ):
            raise ValueError("fixture fields differ from the byte-output contract")
        values = case["input_values"]
        if (
            not isinstance(values, list)
            or type(case["input_length"]) is not int
            or case["input_length"] != len(values)
            or len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH
            or not isinstance(case["expected_output_bytes"], list)
            or any(type(byte) is not int or not 0 <= byte <= 255
                   for byte in case["expected_output_bytes"])
        ):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case["output_capacity"],
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes(case["expected_output_bytes"]))
        tuple_values = tuple(values)
        for oracle in (primary, independent):
            if oracle.expected_output(tuple_values, **options) != expected:
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    combined_docs = (readme + "\n" + rights).lower()
    for required in (
        KRUSKAL_URL, BRIDGE_URL, "CC BY-SA 4.0", "edge-ID-preserving",
        "force", "forbid", "problem statement",
    ):
        if required.lower() not in combined_docs:
            raise ValueError(f"package docs are missing required detail: {required}")
    if "No source code" not in rights and "No source code" not in readme:
        raise ValueError("rights note lacks the clean-room statement")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks the exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
