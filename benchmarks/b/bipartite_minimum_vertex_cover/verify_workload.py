"""Static workload, reference, attribution, and ten-port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "bipartite_minimum_vertex_cover"
SOURCE_URL = "https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/MinimumVertexCover.h"
MATCHING_URL = "https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/DFSMatching.h"
PORTS = (
    "c/b/bipartite_minimum_vertex_cover.c",
    "c3/b/bipartite_minimum_vertex_cover.c3",
    "cpp/b/bipartite_minimum_vertex_cover.cpp",
    "elisa/b/bipartite_minimum_vertex_cover.elisa",
    "mojo/b/bipartite_minimum_vertex_cover.mojo",
    "nim/b/bipartite_minimum_vertex_cover.nim",
    "odin/b/bipartite_minimum_vertex_cover.odin",
    "rust/b/bipartite_minimum_vertex_cover.rs",
    "v/b/bipartite_minimum_vertex_cover.v",
    "zig/b/bipartite_minimum_vertex_cover.zig",
)
CASE_IDS = {
    "empty-graph", "empty-right-partition", "empty-left-partition",
    "single-edge-canonical-right", "left-star-cover", "right-star-cover",
    "two-disjoint-edges-canonical-right", "complete-two-by-two",
    "alternating-path-three-by-three", "canonical-mixed-cover",
    "maximum-complete-eight-by-eight", "negative-row-mask",
    "out-of-domain-right-bit", "nonzero-mask-with-empty-right-side",
    "truncated-left-rows", "trailing-word", "invalid-left-count",
    "invalid-right-count", "maximum-parseable-trailing-word", "null-input",
}

try:
    from .independent_oracle import expected_result as independent_expected_result
    from .primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )
except ImportError:
    from independent_oracle import expected_result as independent_expected_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "unsupported schema")
    require(workload.get("id") == "encyclopedia-bipartite-minimum-vertex-cover-i64-array-scalar-v1",
            "workload ID mismatch")
    require(workload.get("algorithm") == SYMBOL and workload.get("function_symbol") == SYMBOL,
            "algorithm/function symbol mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    source = workload.get("source", {})
    require(source.get("url") == SOURCE_URL and source.get("matching_url") == MATCHING_URL,
            "source URLs mismatch")
    input_spec = workload.get("input", {})
    require(input_spec.get("maximum_valid_length") == MAX_VALID_INPUT_LENGTH
            and input_spec.get("maximum_parseable_length") == MAX_PARSEABLE_INPUT_LENGTH,
            "input framing bounds mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES,
            "workspace bound mismatch")
    output_spec = workload.get("output", {})
    require(output_spec.get("canonical_tie_rule")
            == "Among all minimum covers, choose the lexicographically smallest membership vector in vertex_id_order, with 0 before 1.",
            "canonical output rule mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be a list")
    seen: set[str] = set()
    for case in cases:
        require(isinstance(case, dict), "case must be an object")
        case_id = case.get("id")
        require(isinstance(case_id, str) and case_id not in seen, "duplicate/invalid case ID")
        seen.add(case_id)
        values = case.get("input_values")
        require(isinstance(values, list), f"{case_id}: input_values must be a list")
        null_input = case.get("input_is_null", False)
        declared_length = case.get("input_length")
        require(type(null_input) is bool, f"{case_id}: input_is_null must be boolean")
        require(type(declared_length) is int, f"{case_id}: input_length must be an integer")
        expected = case.get("expected_result")
        require(type(expected) is int, f"{case_id}: expected_result must be an integer")
        primary = expected_result(values, input_is_null=null_input,
                                  input_length=declared_length)
        independent = independent_expected_result(values, input_is_null=null_input,
                                                  input_length=declared_length)
        require(primary == expected, f"{case_id}: published result differs from primary reference")
        require(independent == expected,
                f"{case_id}: published result differs from independent reference")

    require(seen == CASE_IDS, "required fixture inventory differs")
    for relative in PORTS:
        source_text = (ROOT / relative).read_text(encoding="utf-8")
        require(SYMBOL in source_text, f"{relative}: exported symbol missing")
        require(re.search(r"\bTODO\b|PLACEHOLDER", source_text) is None,
                f"{relative}: placeholder remains")
    return len(cases)
