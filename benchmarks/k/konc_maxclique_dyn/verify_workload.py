"""Static package, fixture, attribution, and ten-port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "konc_maxclique_dyn"
PAPER_URL = "https://insilab.org/articles/match2007.pdf"
KACTL_URL = "https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/MaximumClique.h"
PORTS = (
    "c/k/konc_maxclique_dyn.c",
    "c3/k/konc_maxclique_dyn.c3",
    "cpp/k/konc_maxclique_dyn.cpp",
    "elisa/k/konc_maxclique_dyn.elisa",
    "mojo/k/konc_maxclique_dyn.mojo",
    "nim/k/konc_maxclique_dyn.nim",
    "odin/k/konc_maxclique_dyn.odin",
    "rust/k/konc_maxclique_dyn.rs",
    "v/k/konc_maxclique_dyn.v",
    "zig/k/konc_maxclique_dyn.zig",
)
CASE_IDS = {
    "empty-graph", "singleton", "edgeless-six", "path-four", "five-cycle",
    "triangle-with-isolated-vertex", "complete-four", "two-disjoint-triangles",
    "maximum-complete-24", "maximum-path-24", "self-loop", "asymmetric-adjacency",
    "out-of-domain-bit", "negative-mask", "truncated-rows", "trailing-word",
    "maximum-parseable-trailing-word",
}
LARGE_MANUAL_RESULTS = {"maximum-complete-24": 24, "maximum-path-24": 2}

try:
    from .independent_oracle import (
        MAX_INDEPENDENT_VERTICES,
        expected_result as independent_expected_result,
    )
    from .primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )
except ImportError:
    from independent_oracle import (  # type: ignore[no-redef]
        MAX_INDEPENDENT_VERTICES,
        expected_result as independent_expected_result,
    )
    from primary_oracle import (  # type: ignore[no-redef]
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES,
        MAX_WORKSPACE_BYTES,
        expected_result,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "unsupported schema")
    require(workload.get("id") == "encyclopedia-konc-maxclique-dyn-i64-array-scalar-v1",
            "workload ID mismatch")
    require(workload.get("algorithm") == SYMBOL and workload.get("function_symbol") == SYMBOL,
            "algorithm/function symbol mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source", {}).get("url") == PAPER_URL
            and workload.get("source", {}).get("algorithm_description_url") == KACTL_URL,
            "primary references mismatch")
    input_spec = workload.get("input", {})
    require(input_spec.get("encoding") == "[n, adjacency_mask_0, ..., adjacency_mask_(n-1)]"
            and input_spec.get("vertex_count_range") == [0, MAX_VERTICES]
            and input_spec.get("maximum_valid_length") == MAX_VALID_INPUT_LENGTH
            and input_spec.get("maximum_parseable_length") == MAX_PARSEABLE_INPUT_LENGTH,
            "input bounds mismatch")
    output_spec = workload.get("output", {})
    require(output_spec.get("result_range") == [0, MAX_VERTICES]
            and output_spec.get("invalid_input_result") == -1,
            "output contract mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES == 65536,
            "workspace bound mismatch")
    require(workload.get("contract", {}).get("dynamic_reordering")
            == "At each nonempty child candidate set, update the per-depth search count and total coloring-call count. Recompute descending-degree order when 1000*prior_depth_count < 25*new_total_count, matching the 0.025 threshold; ascending vertex ID breaks degree ties.",
            "dynamic reordering contract mismatch")

    cases = workload.get("cases")
    require(isinstance(cases, list) and {case.get("id") for case in cases} == CASE_IDS,
            "fixture IDs mismatch")
    require(len(cases) == len(CASE_IDS), "fixture IDs are duplicated")
    for case in cases:
        values = case.get("input_values")
        require(isinstance(values, list) and case.get("input_length") == len(values),
                f"{case.get('id')}: input frame mismatch")
        primary = expected_result(values)
        require(case.get("expected_result") == primary,
                f"{case['id']}: primary expected result mismatch")
        independent = independent_expected_result(values)
        if independent is not None:
            require(primary == independent, f"{case['id']}: oracle disagreement")
        else:
            require(values[0] > MAX_INDEPENDENT_VERTICES
                    and case["id"] in LARGE_MANUAL_RESULTS
                    and case["expected_result"] == LARGE_MANUAL_RESULTS[case["id"]],
                    f"{case['id']}: undocumented result above independent bound")

    by_id = {case["id"]: case for case in cases}
    require(len(by_id["maximum-complete-24"]["input_values"]) == MAX_VALID_INPUT_LENGTH,
            "maximum valid frame missing")
    require(len(by_id["maximum-parseable-trailing-word"]["input_values"])
            == MAX_PARSEABLE_INPUT_LENGTH, "maximum parseable frame missing")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    require(PAPER_URL in readme and KACTL_URL in readme and PAPER_URL in rights,
            "README or rights note omits source links")
    require("clean-room" in rights and "65,536" in readme
            and "oi_wiki_maximum_clique_branch_bound" in inventory,
            "rights/workspace/dedup documentation missing")
    for relative in PORTS:
        path = ROOT / relative
        require(path.is_file() and SYMBOL in path.read_text(encoding="utf-8"),
                f"port or exported symbol missing: {relative}")
        require(relative in readme, f"README omits port link: {relative}")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("http://", "https://", "#")):
            continue
        require((PACKAGE / target.split("#", 1)[0]).resolve().is_file(),
                f"broken README link: {target}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
