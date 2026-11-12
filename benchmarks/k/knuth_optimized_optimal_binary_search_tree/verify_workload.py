"""Static fixture, oracle, maximum-profile, and ten-port checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from knuth_optimized_optimal_binary_search_tree_oracle import (  # noqa: E402
    MAX_N, MAX_FREQUENCY, MAX_INPUT_LENGTH, MAX_COST, expected_result,
)
from knuth_optimized_optimal_binary_search_tree_verifier_oracle import (  # noqa: E402
    expected_result as cubic_result,
)

PORTS = (
    "c/k/knuth_optimized_optimal_binary_search_tree.c",
    "c3/k/knuth_optimized_optimal_binary_search_tree.c3",
    "cpp/k/knuth_optimized_optimal_binary_search_tree.cpp",
    "elisa/k/knuth_optimized_optimal_binary_search_tree.elisa",
    "mojo/k/knuth_optimized_optimal_binary_search_tree.mojo",
    "nim/k/knuth_optimized_optimal_binary_search_tree.nim",
    "odin/k/knuth_optimized_optimal_binary_search_tree.odin",
    "rust/k/knuth_optimized_optimal_binary_search_tree.rs",
    "v/k/knuth_optimized_optimal_binary_search_tree.v",
    "zig/k/knuth_optimized_optimal_binary_search_tree.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "knuth_optimized_optimal_binary_search_tree"
            or workload.get("function_symbol") != "knuth_optimized_optimal_binary_search_tree"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("workload identity differs from package")
    source = workload.get("source", {})
    if source.get("kind") != "clean-room algorithmic variant of existing optimal-BST recurrence":
        raise ValueError("workload does not identify the clean-room variant")
    if (source.get("knuth_bound_reference") != "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/OptimalBinarySearchTree.java"
            or source.get("input_semantics_reference") != "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/optimal_binary_search_tree.py"):
        raise ValueError("source references differ from the recorded pinned implementations")
    if (workload.get("input", {}).get("maximum_input_values") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("n_range") != [1, MAX_N]
            or workload.get("input", {}).get("frequency_range") != [0, MAX_FREQUENCY]
            or workload.get("output", {}).get("range") != [0, MAX_COST]):
        raise ValueError("workload bounds differ from package oracle")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named cases")
    ids = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in ids:
            raise ValueError("case IDs must be unique")
        ids.add(case["id"])
        actual = expected_result(case.get("input_values"))
        independent = cubic_result(case.get("input_values"))
        if actual != independent or actual != case.get("expected_result"):
            raise ValueError(f"fixture disagrees with oracle(s): {case['id']}")
    maximum = [MAX_N] + [MAX_FREQUENCY] * MAX_N
    if expected_result(maximum) != cubic_result(maximum) or expected_result(maximum) > MAX_COST:
        raise ValueError("maximum profile differs between optimized and cubic oracles")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "Knuth's monotone-root bounds" not in readme or "clean-room" not in rights:
        raise ValueError("README or rights note omits algorithm/provenance")
    if len(PORTS) != 10:
        raise ValueError("checker must list all ten ports")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "knuth_optimized_optimal_binary_search_tree" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README path missing: {relative}")
    return len(cases)
