"""Static metadata, fixture, and source-inventory checks for bounded RCM."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    MAX_VERTICES,
    MIN_VERTICES,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/reverse_cuthill_mckee"
SYMBOL = "reverse_cuthill_mckee"
SOURCE_URL = "https://doi.org/10.1145/800195.805928"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "single-isolated-vertex", "three-vertex-path", "triangle",
    "star-degree-ordered-bfs", "two-disconnected-components",
    "complete-graph-maximum-frame", "null-input", "invalid-empty-frame",
    "invalid-zero-vertex-count", "invalid-vertex-count-above-bound",
    "invalid-self-loop", "invalid-endpoint-out-of-range",
    "invalid-repeated-undirected-edge", "invalid-truncated-edge-pair",
    "invalid-trailing-word", "invalid-maximum-parseable-trailing-word",
    "invalid-edge-count-above-simple-graph-bound",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "r" / f"{SYMBOL}.{extension}"
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
    if (workload.get("id") != "reverse-cuthill-mckee-ordering-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or source.get("reverse_order_url") != "https://doi.org/10.1137/0713020"
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[n, m, (u_0, v_0), ..., (u_(m-1), v_(m-1))]"
            or input_spec.get("vertex_count_range") != [MIN_VERTICES, MAX_VERTICES]
            or input_spec.get("edge_count_range") != "0 <= m <= n*(n-1)/2"
            or input_spec.get("edge_domain") != "0 <= u,v < n; undirected simple graph; no loops or duplicate edges"
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("root_selection") != "For each unvisited component, choose the unvisited vertex of minimum original graph degree, breaking ties by vertex ID."
            or profile.get("bfs_neighbor_order") != "When processing a vertex, enqueue its currently unvisited neighbors in ascending (original degree, vertex ID) order; mark them visited when enqueued."
            or profile.get("component_order") != "Discover components by repeated minimum-degree root selection. Concatenate their BFS sequences in discovery order, then reverse the complete sequence."
            or profile.get("output_packing") != "Return (bandwidth << 24) | rank_word, where rank_word stores the vertex at rank i in bits [3*i,3*i+2], earliest rank in the least-significant chunk."
            or profile.get("bandwidth") != "Maximum absolute difference between endpoint ranks over all graph edges; zero for an edgeless graph."
            or profile.get("complexity") != "The ports use bounded adjacency tables and insertion sorting of each discovered neighbor set: O(n^3) worst-case time and O(n^2) auxiliary space for n<=8."
            or profile.get("tie_breaking") != "All degree ties use the smaller vertex ID."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Packed bandwidth and the reversed Cuthill–McKee permutation of all components concatenated in discovery order."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input contract, ordering profile, or output bounds differ")

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
