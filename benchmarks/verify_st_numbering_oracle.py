"""Static workload, source-path, and brute-force numbering checks."""

from __future__ import annotations

import itertools
import json
from pathlib import Path

from st_numbering_oracle import MAX_EDGES, MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_VERTICES
from st_numbering_oracle import expected_output


ROOT = Path(__file__).resolve().parent
PACKAGE = ROOT / "s" / "st_numbering"
PORTS = {
    "c": "c/s/st_numbering.c",
    "c3": "c3/s/st_numbering.c3",
    "cpp": "cpp/s/st_numbering.cpp",
    "elisa": "elisa/s/st_numbering.elisa",
    "nim": "nim/s/st_numbering.nim",
    "odin": "odin/s/st_numbering.odin",
    "rust": "rust/s/st_numbering.rs",
    "v": "v/s/st_numbering.v",
    "zig": "zig/s/st_numbering.zig",
}
EXPECTED_CASE_IDS = {
    "two-vertex-edge", "triangle", "four-cycle", "complete-four",
    "nonzero-terminals-cycle", "complete-eight-maximum-edges",
    "path-has-articulation", "disconnected", "terminals-not-adjacent",
    "self-loop-invalid", "duplicate-edge-invalid", "endpoint-out-of-range",
    "wrong-length", "same-terminal-invalid", "null-output",
    "short-output-capacity", "null-input",
}


def _brute_force_exists(values: list[int]) -> bool:
    if len(values) < 4:
        return False
    n, m, start, end = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES
            or not 0 <= start < n or not 0 <= end < n or start == end
            or len(values) != 4 + 2 * m):
        return False
    adjacency = [set() for _ in range(n)]
    for edge in range(m):
        u, v = values[4 + 2 * edge:6 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v or v in adjacency[u]:
            return False
        adjacency[u].add(v)
        adjacency[v].add(u)
    if end not in adjacency[start]:
        return False
    internal = [vertex for vertex in range(n) if vertex not in (start, end)]
    for order in itertools.permutations(internal):
        ranks = [0] * n
        ranks[start] = 1
        for rank, vertex in enumerate(order, start=2):
            ranks[vertex] = rank
        ranks[end] = n
        if all(any(ranks[neighbor] < ranks[vertex] for neighbor in adjacency[vertex])
               and any(ranks[neighbor] > ranks[vertex] for neighbor in adjacency[vertex])
               for vertex in internal):
            return True
    return False


def _is_valid_numbering(values: list[int], output: bytes) -> bool:
    n, _m, start, end = values[:4]
    if len(output) != n or sorted(output) != list(range(1, n + 1)):
        return False
    if output[start] != 1 or output[end] != n:
        return False
    adjacency = [set() for _ in range(n)]
    for edge in range(values[1]):
        u, v = values[4 + 2 * edge:6 + 2 * edge]
        adjacency[u].add(v)
        adjacency[v].add(u)
    return all(
        any(output[neighbor] < output[vertex] for neighbor in adjacency[vertex])
        and any(output[neighbor] > output[vertex] for neighbor in adjacency[vertex])
        for vertex in range(n) if vertex not in (start, end)
    )


def validate_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("id") != "st-numbering-even-tarjan-bounded-v1"
            or workload.get("algorithm") != "st_numbering"
            or workload.get("function_symbol") != "st_numbering"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("problem_list_url") != "https://judge.yosupo.jp/"
            or "0304397576900864" not in workload.get("source", {}).get("algorithm_reference", "")
            or workload.get("input", {}).get("vertex_count_range") != [2, MAX_VERTICES]
            or workload.get("input", {}).get("edge_count_range") != [0, MAX_EDGES]
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
            or workload.get("contract", {}).get("complexity")
            != "O(n + m) time and O(n + m) auxiliary space."):
        raise ValueError("st_numbering workload metadata differs from its bounded contract")
    cases = workload.get("cases")
    if (not isinstance(cases, list)
            or {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASE_IDS
            or len(cases) != len(EXPECTED_CASE_IDS)):
        raise ValueError("st_numbering workload has missing or unexpected cases")

    for case in cases:
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        result, output = expected_output(
            values, case.get("output_capacity"), case.get("output_is_null", False),
            input_is_null, case.get("input_length"))
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"st_numbering oracle mismatch: {case.get('id')}")
        if (isinstance(values, list) and not input_is_null
                and result >= 0 and not _is_valid_numbering(values, output)):
            raise ValueError(f"st_numbering fixture violates the rank conditions: {case.get('id')}")
        if (isinstance(values, list) and not input_is_null and result == -1
                and _brute_force_exists(values)):
            raise ValueError(f"st_numbering rejected a graph with an enumerated numbering: {case.get('id')}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if ("https://judge.yosupo.jp/" not in readme
            or "0304397576900864" not in readme
            or "O(n + m)" not in readme):
        raise ValueError("st_numbering README is missing its taxonomy, provenance, or complexity")
    for language, relative in PORTS.items():
        source = ROOT.parent / relative
        if not source.is_file() or "st_numbering" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"st_numbering language source is missing its symbol: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"validated {validate_workload()} st_numbering cases and {len(PORTS)} source paths")
