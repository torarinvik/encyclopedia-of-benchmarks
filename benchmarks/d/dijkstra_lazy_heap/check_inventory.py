"""Static contract, workload, and ten-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "dijkstra_lazy_heap"
SOURCE_URL = "https://cp-algorithms.com/graph/dijkstra_sparse.html"
PORTS = {
    "c": ROOT / "c/d/dijkstra_lazy_heap.c",
    "c3": ROOT / "c3/d/dijkstra_lazy_heap.c3",
    "cpp": ROOT / "cpp/d/dijkstra_lazy_heap.cpp",
    "elisa": ROOT / "elisa/d/dijkstra_lazy_heap.elisa",
    "mojo": ROOT / "mojo/d/dijkstra_lazy_heap.mojo",
    "nim": ROOT / "nim/d/dijkstra_lazy_heap.nim",
    "odin": ROOT / "odin/d/dijkstra_lazy_heap.odin",
    "rust": ROOT / "rust/d/dijkstra_lazy_heap.rs",
    "v": ROOT / "v/d/dijkstra_lazy_heap.v",
    "zig": ROOT / "zig/d/dijkstra_lazy_heap.zig",
}
REQUIRED_CASES = {
    "empty", "empty-invalid-source", "singleton", "stale-heap-entry",
    "several-improvements-before-pop", "equal-distance-ties", "parallel-arcs",
    "zero-weight-cycle", "nonzero-source", "unreachable-component",
    "sparse-chain-24", "int64-max-finite-distance", "overflowing-chain",
    "overflowing-nonimproving-candidate", "negative-edge",
    "unreachable-negative-edge", "invalid-source", "invalid-endpoint",
    "endpoint-before-negative-weight", "invalid-too-many-vertices",
}


def check_inventory() -> list[str]:
    issues: list[str] = []
    required = ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                "primary_oracle.py", "independent_oracle.py", "verify_workload.py")
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not declare {SYMBOL}")
    if not (ROOT / "benchmarks/verify_dijkstra_lazy_heap.py").is_file():
        issues.append("missing dedicated ten-language verifier")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "shortest_path"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity, ABI, or source differs")
    input_spec = workload.get("input", {})
    if (input_spec.get("vertices_range") != [0, 64]
            or input_spec.get("edge_count_range") != [0, 256]
            or input_spec.get("weight_type") != "nonnegative_i64"):
        issues.append("workload input bounds differ from the bounded graph contract")
    if (workload.get("measurement", {}).get("comparison_model") != "shortest_path_call"
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("shortest-path timing model or workspace differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    identifiers = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(identifiers) != len(cases) or len(set(identifiers)) != len(identifiers):
        issues.append("workload case IDs are missing or duplicated")
    missing = REQUIRED_CASES - set(identifiers)
    if missing:
        issues.append("required workload cases are missing: " + ", ".join(sorted(missing)))
    return issues
