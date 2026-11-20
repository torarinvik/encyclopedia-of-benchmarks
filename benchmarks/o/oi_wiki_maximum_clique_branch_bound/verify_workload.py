"""Static workload, reference, markdown-target, and port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]

try:
    from .independent_oracle import (
        MAX_INDEPENDENT_VERTICES,
        expected_result as independent_expected_result,
    )
    from .primary_oracle import (
        MAX_EDGES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import (  # type: ignore[no-redef]
        MAX_INDEPENDENT_VERTICES,
        expected_result as independent_expected_result,
    )
    from primary_oracle import (  # type: ignore[no-redef]
        MAX_EDGES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )

SOURCE_PATHS = (
    "c/o/oi_wiki_maximum_clique_branch_bound.c",
    "c3/o/oi_wiki_maximum_clique_branch_bound.c3",
    "cpp/o/oi_wiki_maximum_clique_branch_bound.cpp",
    "elisa/o/oi_wiki_maximum_clique_branch_bound.elisa",
    "mojo/o/oi_wiki_maximum_clique_branch_bound.mojo",
    "nim/o/oi_wiki_maximum_clique_branch_bound.nim",
    "odin/o/oi_wiki_maximum_clique_branch_bound.odin",
    "rust/o/oi_wiki_maximum_clique_branch_bound.rs",
    "v/o/oi_wiki_maximum_clique_branch_bound.v",
    "zig/o/oi_wiki_maximum_clique_branch_bound.zig",
)
FUNCTION_SYMBOL = "oi_wiki_maximum_clique_branch_bound"
CASE_IDS = {
    "empty-graph", "edgeless-six", "single-edge-and-isolates",
    "five-vertex-path", "five-cycle", "triangle-with-isolated-vertex",
    "complete-four", "two-disjoint-triangles", "maximum-complete-24",
    "maximum-path-24", "self-loop", "asymmetric-adjacency",
    "out-of-domain-bit", "negative-mask", "truncated-rows",
    "trailing-word", "maximum-parseable-trailing-word",
}
LARGE_MANUAL_RESULTS = {"maximum-complete-24": 24, "maximum-path-24": 2}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") ==
            "encyclopedia-oi-wiki-maximum-clique-branch-bound-i64-array-scalar-v1",
            "workload id mismatch")
    require(workload.get("algorithm") == FUNCTION_SYMBOL
            and workload.get("function_symbol") == FUNCTION_SYMBOL,
            "algorithm/function mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source") == {
        "title": "Maximum Clique Search Algorithm",
        "authors": ["OI Wiki contributors"],
        "year": 2026,
        "reference": "OI Wiki graph/max-clique chapter, first MaxClique solver",
        "url": "https://oi-wiki.org/graph/max-clique/",
        "algorithm_attribution": "The bounded profile follows the chapter's increasing-candidate DFS, candidate-neighborhood intersections, remaining-candidate bound, and suffix-optimum dp bound. The port is clean-room and uses no source code or prose.",
        "implementation_status": "clean-room bounded profile; algorithm description only",
    }, "source attribution mismatch")
    require(workload.get("input") == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[n, adjacency_mask_0, ..., adjacency_mask_(n-1)]",
        "vertex_count_range": [0, MAX_VERTICES],
        "adjacency_mask_range": "nonnegative masks with bits only in [0,n)",
        "graph": "simple undirected and loopless; each row mask is symmetric with its opposite row",
        "vertex_label_range": "[0,n)",
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_scalar",
        "encoding": "maximum clique cardinality",
        "result_range": [0, MAX_VERTICES],
        "invalid_input_result": -1,
    }, "output contract mismatch")
    require(workload.get("workspace") == {
        "bytes": MAX_WORKSPACE_BYTES,
        "meaning": "Fixed adjacency and suffix-bound arrays plus recursion state of depth at most 24.",
    }, "workspace mismatch")
    require(workload.get("contract") == {
        "root_order": "Process possible minimum clique vertices in descending ID order.",
        "candidate_order": "At each recursive level, visit candidate vertices in increasing ID order and recurse on the remaining candidates intersected with the chosen vertex's neighborhood.",
        "pruning": "Prune when chosen size plus the remaining candidate count cannot beat the incumbent, or when chosen size plus the previously computed optimum for the candidate's ID suffix cannot beat it.",
        "early_return": "After a search first improves the incumbent for root i, end that root's DFS. Every clique containing i has size at most one plus the best clique wholly in vertices greater than i.",
        "validation": "Reject negative/out-of-domain masks, self loops, asymmetric adjacency, truncated frames, and trailing words.",
        "maximum_input_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_PARSEABLE_INPUT_LENGTH,
    }, "algorithm contract mismatch")
    require(workload.get("measurement") == {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": 10,
        "warmup_rounds": 1,
        "repetitions_per_sample": 10,
    }, "measurement metadata mismatch")
    require(workload.get("oracle_method") == (
        "The primary reference uses ordered DFS and suffix pruning. The independent reference "
        "enumerates all vertex subsets and checks pairwise adjacency; it is used on fixtures "
        "with at most 16 vertices. The 24-vertex cases have hand-derived answers and are "
        "checked against the primary reference only."), "oracle method mismatch")

    cases = workload.get("cases", [])
    require({case.get("id") for case in cases} == CASE_IDS, "fixture IDs differ")
    require(len(cases) == len(CASE_IDS), "fixture IDs are repeated")
    for case in cases:
        values = case.get("input_values")
        require(isinstance(values, list), f"{case.get('id')}: missing input list")
        require(case.get("input_length") == len(values), f"{case['id']}: length mismatch")
        primary = expected_result(values)
        require(case.get("expected_result") == primary,
                f"{case['id']}: primary oracle mismatch")
        independent = independent_expected_result(values)
        if independent is not None:
            require(primary == independent,
                    f"{case['id']}: independent oracle mismatch")
        else:
            require(values[0] > MAX_INDEPENDENT_VERTICES,
                    f"{case['id']}: oracle skipped within exhaustive bound")
            require(case["id"] in LARGE_MANUAL_RESULTS,
                    f"{case['id']}: fixture above exhaustive bound is not documented")
            require(case["expected_result"] == LARGE_MANUAL_RESULTS[case["id"]],
                    f"{case['id']}: manual maximum-size result mismatch")

    by_id = {case["id"]: case for case in cases}
    require(len(by_id["maximum-complete-24"]["input_values"]) == MAX_VALID_INPUT_LENGTH,
            "maximum-size valid fixture missing")
    require(len(by_id["maximum-parseable-trailing-word"]["input_values"])
            == MAX_PARSEABLE_INPUT_LENGTH,
            "maximum parseable trailing-word fixture missing")
    require(MAX_EDGES == 276 and MAX_VALID_INPUT_LENGTH == 25,
            "published bounds mismatch")

    for source in SOURCE_PATHS:
        port = ROOT / source
        require(port.is_file(), f"missing port: {source}")
        require(FUNCTION_SYMBOL in port.read_text(encoding="utf-8"),
                f"missing exported symbol in {source}")
    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    require(readme_path.is_file(), "README missing")
    require(rights_path.is_file(), "rights note missing")
    readme = readme_path.read_text(encoding="utf-8")
    rights = rights_path.read_text(encoding="utf-8")
    require(workload["source"]["url"] in readme, "README omits algorithm reference")
    require("CC BY-SA 4.0" in rights and "SATA" in rights
            and "clean-room" in rights, "rights note omits source license context")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("http://", "https://", "#")):
            continue
        local_target = target.split("#", 1)[0]
        require((PACKAGE / local_target).resolve().is_file(),
                f"broken README target: {target}")


if __name__ == "__main__":
    validate()
