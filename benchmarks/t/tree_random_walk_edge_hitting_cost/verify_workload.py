"""Static package metadata, fixture, oracle, and implementation-path checks."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
from primary_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_N, MAX_OUTPUT_BYTES, MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES, expected_output,
)
from independent_oracle import expected_output as independent_output  # noqa: E402

SOURCE_URL = "https://oi-wiki.org/graph/tree-random-walk/"
PORTS = (
    "c/t/tree_random_walk_edge_hitting_cost.c",
    "c3/t/tree_random_walk_edge_hitting_cost.c3",
    "cpp/t/tree_random_walk_edge_hitting_cost.cpp",
    "elisa/t/tree_random_walk_edge_hitting_cost.elisa",
    "mojo/t/tree_random_walk_edge_hitting_cost.mojo",
    "nim/t/tree_random_walk_edge_hitting_cost.nim",
    "odin/t/tree_random_walk_edge_hitting_cost.odin",
    "rust/t/tree_random_walk_edge_hitting_cost.rs",
    "v/t/tree_random_walk_edge_hitting_cost.v",
    "zig/t/tree_random_walk_edge_hitting_cost.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "tree_random_walk_edge_hitting_cost"
            or workload.get("function_symbol") != "tree_random_walk_edge_hitting_cost"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("method_reference") != SOURCE_URL):
        raise ValueError("workload identity or method provenance differs")
    contract = workload.get("contract", {})
    if (contract.get("input_layout") != "[n,root,(u,v,w)*(n-1)]"
            or contract.get("vertex_count_range") != [1, MAX_N]
            or contract.get("edge_weight_range") != [1, 9]
            or "up[root]=0" not in contract.get("rooted_recurrence", "")
            or "without writes" not in contract.get("invalid_precedence", "")):
        raise ValueError("workload contract differs from the reviewed bound")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload input, output, or workspace bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named cases")
    required = {
        "single-vertex-empty-output", "single-vertex-null-output",
        "single-weighted-edge", "reversed-edge-record", "weighted-chain-root-in-middle",
        "branched-tree-mixed-record-orientations", "nonzero-root-and-arbitrary-record-order",
        "maximum-weight-edge", "out-of-range-root", "zero-weight-edge", "self-loop",
        "cycle-instead-of-tree", "truncated-edge-record", "extra-word-frame",
        "malformed-before-output-capacity", "short-output-capacity", "null-output", "null-input",
    }
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("case is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate case ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        args = (values, case.get("output_capacity"), case.get("output_is_null", False),
                case.get("input_is_null", False), case.get("input_length"))
        primary = expected_output(*args)
        independent = independent_output(*args)
        if (case.get("input_length") != len(values)
                or not isinstance(case.get("expected_output_hex"), str)
                or primary != independent
                or primary[0] != case.get("expected_result")):
            raise ValueError(f"case differs between direct oracles: {case['id']}")
        if ("expected_output_hex" in case
                and primary[1].hex() != case["expected_output_hex"].lower()):
            raise ValueError(f"pinned output differs from both oracles: {case['id']}")
        if primary[0] >= 0 and len(primary[1]) != primary[0]:
            raise ValueError(f"successful byte count differs: {case['id']}")
        if primary[0] < 0 and primary[1]:
            raise ValueError(f"error case contains bytes: {case['id']}")
    if not required.issubset(seen):
        raise ValueError(f"workload omits cases: {sorted(required - seen)}")

    profile = workload.get("generated_profile", {})
    if (profile.get("maximum_n") != MAX_N
            or profile.get("maximum_input_length") != MAX_VALID_INPUT_LENGTH
            or profile.get("maximum_output_bytes") != MAX_OUTPUT_BYTES):
        raise ValueError("generated profile differs from bounded maximum")
    # Fixed 16-node branching tree: all 15 vertices other than root 7 attach by
    # deterministic parent choices, yielding a valid maximum-size stress frame.
    values = [MAX_N, 7]
    for vertex in range(MAX_N):
        if vertex == 7:
            continue
        parent = 7 if vertex in (0, 3, 11, 15) else (vertex - 1 if vertex < 7 else 7)
        values.extend((vertex, parent, 1 + ((vertex * 5) % 9)))
    result = expected_output(values, MAX_OUTPUT_BYTES)
    oracle = independent_output(values, MAX_OUTPUT_BYTES)
    if (len(values) != MAX_VALID_INPUT_LENGTH or result != oracle
            or result[0] != MAX_OUTPUT_BYTES):
        raise ValueError("maximum-size generated tree differs between references")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "No upstream code or prose" not in rights:
        raise ValueError("README or rights note omits provenance or clean-room scope")
    if len(PORTS) != 10:
        raise ValueError("checker must enumerate all ten source paths")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "tree_random_walk_edge_hitting_cost" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"missing implementation source: {relative}")
        if relative not in readme:
            raise ValueError(f"README omits implementation source: {relative}")
    return len(cases)


def main() -> None:
    print(f"checked {verify_workload()} cases and {len(PORTS)} implementation paths")


if __name__ == "__main__":
    main()
