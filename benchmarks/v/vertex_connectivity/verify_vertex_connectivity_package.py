"""Static inventory and oracle-fixture checker; do not invoke while profiling."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys

BENCHMARKS = Path(__file__).resolve().parents[2]
ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(BENCHMARKS))

ALGORITHM = "vertex_connectivity"
SOURCE_URL = "https://cp-algorithms.com/graph/edge_vertex_connectivity.html"
PORTS = (
    "c/v/vertex_connectivity.c",
    "c3/v/vertex_connectivity.c3",
    "cpp/v/vertex_connectivity.cpp",
    "elisa/v/vertex_connectivity.elisa",
    "mojo/v/vertex_connectivity.mojo",
    "nim/v/vertex_connectivity.nim",
    "odin/v/vertex_connectivity.odin",
    "rust/v/vertex_connectivity.rs",
    "v/v/vertex_connectivity.v",
    "zig/v/vertex_connectivity.zig",
)
CASE_IDS = {
    "empty-graph", "single-vertex", "disconnected-pairs",
    "complete-two-vertex-graph", "three-vertex-path", "triangle", "four-cycle",
    "two-vertex-disjoint-paths-between-nonadjacent-pair",
    "complete-four-graph-missing-one-edge", "two-triangles-sharing-an-articulation",
    "duplicate-edge-and-self-loop", "isolated-vertex", "maximum-complete-graph",
    "null-input", "negative-vertex-count", "vertex-count-over-bound",
    "edge-count-over-bound", "out-of-range-endpoint", "truncated-edge",
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
    primary = _load_oracle("vertex_connectivity_oracle.py")
    verifier = _load_oracle("vertex_connectivity_deletion_oracle.py")
    expected_bounds = (10, 45, 92)
    for oracle in (primary, verifier):
        actual_bounds = (oracle.MAX_VERTICES, oracle.MAX_EDGES, oracle.MAX_INPUT_LENGTH)
        if actual_bounds != expected_bounds:
            raise ValueError("oracle bounds differ from the workload profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("vertex_count_range") != [0, 10]
            or workload.get("input", {}).get("edge_count_range") != [0, 45]
            or workload.get("input", {}).get("maximum_input_length") != 92
            or workload.get("output", {}).get("maximum_result") != 9
            or workload.get("workspace", {}).get("elements") != 470
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_scalar_call"):
        raise ValueError("workload metadata differs from the bounded profile")
    cases = workload.get("cases")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are missing or have duplicate identifiers")
    allowed = {"id", "input_values", "input_length", "input_is_null", "expected_result"}
    required = {"id", "input_values", "input_length", "expected_result"}
    for case in cases:
        if not isinstance(case, dict) or set(case)-allowed or not required.issubset(case):
            raise ValueError("fixture fields differ from the scalar graph contract")
        values = case["input_values"]
        if (not isinstance(values, list) or type(case["input_length"]) is not int
                or case["input_length"] != len(values)
                or len(values) > primary.MAX_INPUT_LENGTH
                or type(case["expected_result"]) is not int):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        for oracle in (primary, verifier):
            if oracle.expected_result(values, **options) != case["expected_result"]:
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required_text in (SOURCE_URL, "vertex-splitting", "470 workspace elements",
                          "clean-room", "articulation_points"):
        if required_text not in readme:
            raise ValueError(f"README is missing contract/provenance detail: {required_text}")
    if SOURCE_URL not in rights or "CC BY-SA 4.0" not in rights or "No article prose" not in rights:
        raise ValueError("rights attribution or clean-room statement is incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
