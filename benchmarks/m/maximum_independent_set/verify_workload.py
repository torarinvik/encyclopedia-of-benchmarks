"""Static metadata and oracle consistency checks for the bounded MIS profile."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from maximum_independent_set_oracle import (  # noqa: E402
    MAX_EDGES, MAX_INPUT_LENGTH, MAX_N, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES, expected_result,
)
from maximum_independent_set_verifier_oracle import (  # noqa: E402
    expected_result as independent_expected_result,
)

SOURCE_PATHS = (
    "c/m/maximum_independent_set.c",
    "c3/m/maximum_independent_set.c3",
    "cpp/m/maximum_independent_set.cpp",
    "elisa/m/maximum_independent_set.elisa",
    "mojo/m/maximum_independent_set.mojo",
    "nim/m/maximum_independent_set.nim",
    "odin/m/maximum_independent_set.odin",
    "rust/m/maximum_independent_set.rs",
    "v/m/maximum_independent_set.v",
    "zig/m/maximum_independent_set.zig",
)
CASE_IDS = {
    "empty-graph", "edgeless-six", "single-edge-and-isolates",
    "five-vertex-path", "five-cycle", "triangle-with-isolated-vertex",
    "complete-four", "maximum-path", "self-loop",
    "duplicate-undirected-edge", "out-of-range-endpoint", "truncated-edge",
    "trailing-word",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "encyclopedia-maximum-independent-set-i64-array-scalar-v1",
            "workload id mismatch")
    require(workload.get("algorithm") == "maximum_independent_set"
            and workload.get("function_symbol") == "maximum_independent_set",
            "algorithm/function mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source") == {
        "title": "Exact Algorithms for Maximum Independent Set",
        "authors": ["Fabrizio Grandoni"],
        "year": 2016,
        "reference": "Encyclopedia of Algorithms, chapter 514",
        "url": "https://doi.org/10.1007/978-1-4939-2864-4_514",
        "algorithm_attribution": "The chapter surveys exact maximum-independent-set methods; this bounded clean-room port uses maximum-degree include/exclude branching with its own greedy clique-cover upper bound.",
        "implementation_status": "clean-room bounded profile; no source code or chapter text copied",
    }, "source attribution mismatch")
    require(workload.get("input") == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[n,m,u0,v0,...]",
        "vertex_count_range": [0, MAX_N],
        "edge_count_range": [0, MAX_EDGES],
        "graph": "simple undirected; each edge occurs once",
        "vertex_label_range": "[0,n)",
        "maximum_valid_length": MAX_INPUT_LENGTH - 1,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload.get("output") == {
        "kind": "signed_64_bit_scalar",
        "encoding": "maximum independent-set cardinality",
        "result_range": [0, MAX_N],
        "invalid_input_result": -1,
    }, "output contract mismatch")
    require(workload.get("workspace", {}).get("bytes") == MAX_WORKSPACE_BYTES,
            "workspace mismatch")
    require(workload.get("contract") == {
        "branching": "Choose a remaining vertex with maximum degree in the remaining induced graph; explore inclusion before exclusion.",
        "upper_bound": "Partition remaining vertices greedily into cliques; an independent set contains at most one vertex from each clique.",
        "edge_validation": "Reject loops, repeated undirected edges, out-of-range endpoints, truncation, and trailing words.",
        "maximum_input_length": MAX_INPUT_LENGTH - 1,
        "maximum_parseable_input_length": MAX_PARSEABLE_INPUT_LENGTH,
    }, "algorithm contract mismatch")
    require(workload.get("measurement") == {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": 10,
        "warmup_rounds": 1,
        "repetitions_per_sample": 10,
    }, "measurement metadata mismatch")
    cases = workload.get("cases", [])
    require({case.get("id") for case in cases} == CASE_IDS, "fixture IDs differ")
    require(len(cases) == len(CASE_IDS), "fixture IDs are repeated")
    for case in cases:
        values = case.get("input_values")
        require(case.get("input_length") == len(values), f"{case['id']}: length mismatch")
        primary = expected_result(values)
        independent = independent_expected_result(values)
        require(case.get("expected_result") == primary,
                f"{case['id']}: primary oracle mismatch")
        require(primary == independent, f"{case['id']}: independent oracle mismatch")
    for source in SOURCE_PATHS:
        path = ROOT / source
        require(path.is_file(), f"missing port: {source}")
        require("maximum_independent_set" in path.read_text(encoding="utf-8"),
                f"missing exported symbol in {source}")
    require((PACKAGE / "README.md").is_file(), "README missing")
    require((PACKAGE / "RIGHTS.md").is_file(), "rights note missing")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    require(workload["source"]["url"] in readme, "README omits the algorithm reference")
    require("clean-room" in rights and "No source code" in rights,
            "rights note does not describe clean-room provenance")


if __name__ == "__main__":
    validate()
