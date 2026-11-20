"""Static contract and ten-port inventory checks for sparse Prim."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "prim_sparse_heap"
SOURCE_URL = "https://cp-algorithms.com/graph/mst_prim.html"
PORTS = {
    "c": ROOT / "c/p/prim_sparse_heap.c",
    "c3": ROOT / "c3/p/prim_sparse_heap.c3",
    "cpp": ROOT / "cpp/p/prim_sparse_heap.cpp",
    "elisa": ROOT / "elisa/p/prim_sparse_heap.elisa",
    "mojo": ROOT / "mojo/p/prim_sparse_heap.mojo",
    "nim": ROOT / "nim/p/prim_sparse_heap.nim",
    "odin": ROOT / "odin/p/prim_sparse_heap.odin",
    "rust": ROOT / "rust/p/prim_sparse_heap.rs",
    "v": ROOT / "v/p/prim_sparse_heap.v",
    "zig": ROOT / "zig/p/prim_sparse_heap.zig",
}
REQUIRED_CASES = {
    "empty", "empty-with-record-invalid", "single-vertex", "classic-four-vertex-graph",
    "parallel-edge-decrease-key", "equal-frontier-keys", "zero-weights-and-self-loops",
    "disconnected", "maximum-weight-total", "sparse-chain-64", "bad-length",
    "bad-endpoint", "negative-weight", "weight-out-of-range", "too-many-vertices",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not export {SYMBOL}")
    if not (ROOT / "benchmarks/verify_prim_sparse_heap.py").is_file():
        issues.append("missing dedicated all-language verifier")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("comparison_model") != "i64_array_scalar_call"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity, ABI comparison model, or source differs")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_vertex_count") != 64
            or input_spec.get("maximum_edge_record_count") != 4096
            or input_spec.get("maximum_parseable_input_length") != 12290
            or input_spec.get("edge_weights") != [0, 2147483647]):
        issues.append("workload bounds differ from the shared Prim contract")
    if (workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or workload.get("measurement", {}).get("sample_count") != 5
            or workload.get("measurement", {}).get("warmup_rounds") != 1
            or workload.get("measurement", {}).get("repetitions_per_sample") != 1):
        issues.append("measurement metadata differs from the bounded scalar profile")
    if (workload.get("workspace", {}).get("bytes") != 200704
            or workload.get("workspace", {}).get("adjacency_incidence_bound") != 8192
            or workload.get("workspace", {}).get("heap_entry_bound") != 64):
        issues.append("fixed workspace metadata differs from the ports")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no cases"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(ids) != len(set(ids)):
        issues.append("workload IDs are missing or duplicated")
    missing = REQUIRED_CASES - set(ids)
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        if (not isinstance(values, list) or case.get("input_length") != len(values)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or type(case.get("expected_result")) is not int):
            issues.append(f"invalid packed workload frame: {case.get('id')}")
    return issues
