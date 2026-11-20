"""Static metadata, fixture, and source-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_EDGES,
    MAX_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    MAX_VERTICES,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/boykov_kolmogorov_maxflow"
SYMBOL = "boykov_kolmogorov_maxflow"
SOURCE_URL = "https://doi.org/10.1109/TPAMI.2004.60"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "disconnected-terminals", "single-directed-edge", "parallel-arcs",
    "two-disjoint-capacity-limited-paths", "orphan-reparent-and-free",
    "antiparallel-arcs", "zero-capacity-edge", "null-input", "empty-frame",
    "same-terminals", "edge-count-above-bound", "endpoint-out-of-range",
    "self-loop", "capacity-above-bound", "truncated-arc", "trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "b" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    profile = workload.get("algorithm_profile", {})
    source = workload.get("source", {})
    measurement = workload.get("measurement", {})
    if (workload.get("id") != "boykov-kolmogorov-maxflow-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or source.get("implementation_notes_url") != "https://www.boost.org/doc/libs/develop/libs/graph/doc/html/graph/algorithms/network_flow/boykov_kolmogorov_max_flow.html"
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[n,m,s,t,(u_0,v_0,c_0),...,(u_(m-1),v_(m-1),c_(m-1))]"
            or input_spec.get("vertex_count_range") != [2, MAX_VERTICES]
            or input_spec.get("edge_count_range") != [0, MAX_EDGES]
            or input_spec.get("terminal_rule") != "0<=s,t<n and s!=t"
            or input_spec.get("endpoint_rule") != "0<=u,v<n and u!=v; parallel and antiparallel arcs allowed"
            or input_spec.get("capacity_range") != [0, 15]
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("residual_graph") != "Aggregate parallel input capacities in a directed n-by-n residual matrix; initialize R[u][v] to the sum of capacities for each directed input arc u->v."
            or profile.get("tree_growth") != "Initialize active FIFO queue [s,t]. Pop vertices FIFO and scan neighbors by ascending ID. Source-tree u grows over R[u][v]>0; sink-tree u grows backward over R[v][u]>0. Add a free neighbor to the active tree. On first opposite-tree encounter, record the oriented source-to-sink bridge and end growth."
            or profile.get("bridge_resumption") != "After finding a bridge, requeue its active endpoint at the queue tail before augmentation, so unscanned neighbors remain eligible after tree adoption."
            or profile.get("augmentation") != "Join the source parent chain, bridge, and sink parent chain; subtract the path bottleneck from each forward residual and add it to the reverse residual. Queue saturated tree children as orphans in source-to-sink path order."
            or profile.get("orphan_adoption") != "Process orphans FIFO. Choose the lowest-ID same-tree parent with a positive parent-to-orphan residual edge and a positive-residual parent chain to its tree root. If none exists, free the orphan, activate same-tree neighbors with a positive parent-to-orphan edge in ascending ID order, and enqueue former children as orphans in ascending ID order."
            or profile.get("complexity") != "Let C be the sum of input capacities leaving s; C<=240 and at most C augmentations occur. The bounded profile uses O((C+1)*n^4) worst-case time and O(n^2+m) auxiliary space for n<=8."
            or profile.get("tie_breaking") != "Active and orphan queues are FIFO; all vertex scans use ascending vertex ID; replacement-parent adoption chooses the lowest eligible vertex ID."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Maximum s-to-t flow value; -1 for invalid input."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, BK profile, or output bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if primary(values, input_is_null, length) != expected:
            issues.append(f"primary-reference fixture mismatch: {case_id}")
        if independent(values, input_is_null, length) != expected:
            issues.append(f"independent-reference fixture mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
