"""Static source/workload checks for the link-cut-tree package."""

from __future__ import annotations

import json
from pathlib import Path

from link_cut_tree_oracle import MAX_INPUT_LENGTH, MAX_OPERATIONS, MAX_OUTPUT_BYTES
from link_cut_tree_oracle import MAX_VERTICES, WEIGHT_LIMIT, expected_output

ROOT = Path(__file__).resolve().parent
PACKAGE = ROOT / "l" / "link_cut_tree"
PORTS = {
    "c": "c/l/link_cut_tree.c",
    "c3": "c3/l/link_cut_tree.c3",
    "cpp": "cpp/l/link_cut_tree.cpp",
    "elisa": "elisa/l/link_cut_tree.elisa",
    "nim": "nim/l/link_cut_tree.nim",
    "odin": "odin/l/link_cut_tree.odin",
    "rust": "rust/l/link_cut_tree.rs",
    "v": "v/l/link_cut_tree.v",
    "zig": "zig/l/link_cut_tree.zig",
}
CASE_IDS = {
    "link-and-path-sums", "cycle-link-rejected-then-cut", "path-sum-after-links",
    "missing-cut-and-disconnected-query", "singleton-query-and-self-cut",
    "unknown-operation", "weight-out-of-range", "wrong-length", "null-output",
    "short-output-capacity", "null-input",
}


def validate_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("id") != "link-cut-tree-bounded-dynamic-forest-v1"
            or workload.get("algorithm") != "link_cut_tree"
            or workload.get("function_symbol") != "link_cut_tree"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("url") != "https://en.oi-wiki.org/ds/lct/"
            or workload.get("input", {}).get("vertex_count_range") != [1, MAX_VERTICES]
            or workload.get("input", {}).get("operation_count_range") != [1, MAX_OPERATIONS]
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("weight_range") != [0, WEIGHT_LIMIT]
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != 2048
            or workload.get("contract", {}).get("complexity")
            != "O(log n) amortized per operation and O(n) data-structure storage."):
        raise ValueError("link_cut_tree workload metadata differs from its contract")
    cases = workload.get("cases")
    if (not isinstance(cases, list)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS
            or len(cases) != len(CASE_IDS)):
        raise ValueError("link_cut_tree workload has missing or unexpected cases")
    for case in cases:
        result, output = expected_output(
            case.get("input_values"), case.get("output_capacity"),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case.get("input_length"))
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"link_cut_tree oracle mismatch: {case.get('id')}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if ("https://en.oi-wiki.org/ds/lct/" not in readme
            or "O(log n) amortized" not in readme or "BFS" not in readme):
        raise ValueError("link_cut_tree README is missing provenance, complexity, or oracle description")
    for language, relative in PORTS.items():
        source_path = ROOT.parent / relative
        if not source_path.is_file():
            raise ValueError(f"missing {language} link_cut_tree source: {relative}")
        text = source_path.read_text(encoding="utf-8")
        if "link_cut_tree" not in text:
            raise ValueError(f"link_cut_tree symbol is missing from {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"validated {validate_workload()} link_cut_tree cases and {len(PORTS)} source paths")
