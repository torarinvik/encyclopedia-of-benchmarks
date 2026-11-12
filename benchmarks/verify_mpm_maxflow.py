"""Static package-contract checks for the bounded MPM maximum-flow profile."""

from pathlib import Path

from mpm_maxflow_oracle import (
    MAX_CAPACITY,
    MAX_EDGES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_VERTICES,
    expected_result,
)


PORTS = (
    "c/m/mpm_maxflow.c",
    "c3/m/mpm_maxflow.c3",
    "cpp/m/mpm_maxflow.cpp",
    "elisa/m/mpm_maxflow.elisa",
    "mojo/m/mpm_maxflow.mojo",
    "nim/m/mpm_maxflow.nim",
    "odin/m/mpm_maxflow.odin",
    "rust/m/mpm_maxflow.rs",
    "v/m/mpm_maxflow.v",
    "zig/m/mpm_maxflow.zig",
)

CASE_IDS = {
    "classic-six-vertex-network", "parallel-arcs", "antiparallel-arcs",
    "internal-bottlenecks", "alternate-terminal-labels", "disconnected-sink",
    "zero-capacity-edge", "capacity-boundary", "empty-edge-list",
    "wrong-packed-length", "source-equals-sink", "self-loop",
    "endpoint-out-of-range", "negative-capacity", "capacity-above-local-bound",
    "dimension-above-local-bound", "edge-count-above-local-bound",
    "maximum-parseable-length",
}

_ROOT = Path(__file__).resolve().parents[1]


def validate_workload(workload: dict) -> None:
    """Reject workload drift, bad fixtures, or missing ten-language source ports."""
    if not isinstance(workload, dict):
        raise ValueError("mpm_maxflow workload must be an object")
    cases = workload.get("cases")
    if (set(workload) != {
            "schema_version", "id", "algorithm", "function_symbol", "input", "output",
            "workspace", "source", "measurement", "cases"}
            or workload.get("schema_version") != 1
            or workload.get("id") != "cp-algorithms-mpm-maxflow-bounded-directed-v1"
            or workload.get("algorithm") != "mpm_maxflow"
            or workload.get("function_symbol") != "mpm_maxflow"
            or workload.get("input") != {
                "kind": "i64_array_scalar",
                "encoding": "[N, M, source, sink, (from, to, capacity)*M]",
                "vertex_count_range": [2, MAX_VERTICES],
                "edge_count_range": [0, MAX_EDGES],
                "vertex_ids": "1-based",
                "self_loops_allowed": False,
                "parallel_edges_allowed": True,
                "antiparallel_edges_allowed": True,
                "capacity_range": [0, MAX_CAPACITY],
                "maximum_valid_input_length": MAX_VALID_INPUT_LENGTH,
                "maximum_parseable_input_length": MAX_PARSEABLE_INPUT_LENGTH,
                "maximum_flow": MAX_EDGES * MAX_CAPACITY,
                "invalid_result": -1,
            }
            or workload.get("output") != {
                "kind": "signed_64_bit_integer",
                "definition": "Maximum integral flow from source to sink.",
                "invalid_input_result": -1,
            }
            or workload.get("workspace") != {
                "bytes": 2048,
                "meaning": "Bound for the fixed 8-by-8 residual and layered-arc matrices, per-vertex arrays, and bounded recursive push frames.",
            }
            or workload.get("source") != {
                "title": "Maximum flow - MPM algorithm",
                "authors": ["CP-Algorithms contributors"],
                "reference": "CP-Algorithms",
                "url": "https://cp-algorithms.com/graph/mpm.html",
                "algorithm_attribution": "Level graph phases with minimum-potential reference vertex and node deletion",
                "implementation_status": "clean-room bounded MPM ports",
            }
            or workload.get("measurement") != {
                "comparison_model": "i64_array_scalar_call",
                "sample_count": 8,
                "warmup_rounds": 2,
                "repetitions_per_sample": 1000,
            }
            or not isinstance(cases, list)
            or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("mpm_maxflow metadata differs from its bounded directed-network contract")

    for relative in PORTS:
        source_path = _ROOT / relative
        if not source_path.is_file():
            raise ValueError(f"mpm_maxflow language port is missing: {relative}")
        if "mpm_maxflow" not in source_path.read_text(encoding="utf-8"):
            raise ValueError(f"mpm_maxflow language port does not expose its registered symbol: {relative}")

    readme = (_ROOT / "benchmarks/m/mpm_maxflow/README.md").read_text(encoding="utf-8")
    if ("https://cp-algorithms.com/graph/mpm.html" not in readme
            or "parallel and antiparallel arcs" not in readme
            or "Dinic's per-vertex blocking-flow DFS" not in readme
            or "`O(V^3)`" not in readme or "`O(V^2 + M)`" not in readme
            or "2,048 bytes" not in readme):
        raise ValueError("mpm_maxflow README is missing provenance or distinctness notes")

    for case in cases:
        values = case.get("input_values")
        if (set(case) != {"id", "input_values", "expected_result"}
                or not isinstance(values, list)
                or len(values) > MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
                or type(case.get("expected_result")) is not int
                or case["expected_result"] != expected_result(values)):
            raise ValueError(f"mpm_maxflow fixture differs from its exhaustive-cut oracle: {case.get('id')}")
