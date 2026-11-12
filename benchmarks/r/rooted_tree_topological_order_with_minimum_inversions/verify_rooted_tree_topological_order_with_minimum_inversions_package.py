"""Static metadata and optimum-certificate checks for this package."""

from __future__ import annotations

import json
import sys
from pathlib import Path

BENCHMARKS = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BENCHMARKS))

from rooted_tree_topological_order_with_minimum_inversions_oracle import (
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_WEIGHT,
    expected_output as contraction_oracle,
)
from rooted_tree_topological_order_with_minimum_inversions_checker import (
    verify_certificate,
)


ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "r" / "rooted_tree_topological_order_with_minimum_inversions"
ALGORITHM = "rooted_tree_topological_order_with_minimum_inversions"
TASK_URL = (
    "https://raw.githubusercontent.com/yosupo06/library-checker-problems/"
    "master/tree/rooted_tree_topological_order_with_minimum_inversions/task.md"
)
LIMITS_URL = (
    "https://raw.githubusercontent.com/yosupo06/library-checker-problems/"
    "master/tree/rooted_tree_topological_order_with_minimum_inversions/info.toml"
)
PORTS = (
    "c/r/rooted_tree_topological_order_with_minimum_inversions.c",
    "c3/r/rooted_tree_topological_order_with_minimum_inversions.c3",
    "cpp/r/rooted_tree_topological_order_with_minimum_inversions.cpp",
    "elisa/r/rooted_tree_topological_order_with_minimum_inversions.elisa",
    "mojo/r/rooted_tree_topological_order_with_minimum_inversions.mojo",
    "nim/r/rooted_tree_topological_order_with_minimum_inversions.nim",
    "odin/r/rooted_tree_topological_order_with_minimum_inversions.odin",
    "rust/r/rooted_tree_topological_order_with_minimum_inversions.rs",
    "v/r/rooted_tree_topological_order_with_minimum_inversions.v",
    "zig/r/rooted_tree_topological_order_with_minimum_inversions.zig",
)
CASE_IDS = {
    "single-root-zero-weights",
    "two-vertex-chain-objective",
    "star-descending-ratio-order",
    "positive-c-zero-d-ratio-is-infinite",
    "zero-zero-ratio-is-smallest",
    "equal-ratio-prefers-larger-component-label",
    "nested-contractions",
    "maximum-local-size-zero-weights",
    "parent-must-precede-child-index",
    "negative-weight-is-invalid",
    "weight-sum-limit-is-enforced",
    "truncated-weight-array",
    "local-vertex-limit-is-enforced",
    "trailing-input-word-is-invalid",
    "insufficient-output-capacity",
    "null-output-buffer",
    "null-input-buffer",
}


def validate_package() -> None:
    if (MAX_N, MAX_WEIGHT, MAX_VALID_INPUT_LENGTH,
            MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES) != (12, 1_000_000, 36, 37, 104):
        raise ValueError("oracle constants differ from the bounded profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_source = {
        "title": "Rooted Tree Topological Order with Minimum Inversions",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker task contract and clean-room contraction/ratio-order profile",
        "url": TASK_URL,
        "limits_url": LIMITS_URL,
        "algorithm_attribution": "DSU component contraction ordered by descending aggregate C/D ratio",
        "implementation_status": "clean-room bounded profile",
    }
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,parent[1..N-1],C[0..N-1],D[0..N-1]]",
        "N_range": [1, MAX_N],
        "parent_rule": "0 <= parent[i] < i for every i in 1..N-1; vertex 0 is the root",
        "weight_range": [0, MAX_WEIGHT],
        "weight_sum_range": [0, MAX_WEIGHT],
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "byte_array",
        "encoding": "little-endian signed 64-bit words [minimum_objective,vertex_0,...,vertex_N-1]",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_capacity_result": -2,
        "output_untouched_on_error": True,
    }
    expected_contract = {
        "objective": "minimize sum over each later vertex v of C[v] times the sum of D values on earlier vertices",
        "topological_constraint": "every ancestor precedes each descendant",
        "official_N_range": [1, 200_000],
        "official_weight_range": [0, 1_000_000_000],
        "official_weight_sum_range": [0, 1_000_000_000],
        "certificate": "minimum objective followed by one optimal topological permutation; any optimum is accepted",
    }
    cases = workload.get("cases")
    expected_workload = {
        "schema_version": 1,
        "id": "library-checker-rooted-tree-topological-order-minimum-inversions-bounded-i64-array-bytes-output-v1",
        "algorithm": ALGORITHM,
        "function_symbol": ALGORITHM,
        "abi": "i64_array_bytes_output",
        "description": "Minimum weighted inversion objective over rooted-tree topological orders, by ratio-ordered DSU contraction.",
        "source": expected_source,
        "input": expected_input,
        "output": expected_output,
        "workspace": {
            "bytes": MAX_OUTPUT_BYTES,
            "meaning": "Maximum output-buffer capacity; DSU, contraction links, and weight arrays are separate bounded storage.",
        },
        "contract": expected_contract,
        "measurement": {
            "comparison_model": "i64_array_bytes_output_call",
            "sample_count": 6,
            "warmup_rounds": 1,
            "repetitions_per_sample": 100,
        },
        "cases": cases,
    }
    if workload != expected_workload:
        raise ValueError("workload metadata differs from the package contract")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are incomplete or have duplicate identifiers")

    for case in cases:
        if (not isinstance(case, dict)
                or set(case) - {"id", "input_values", "input_length", "output_capacity",
                                "input_is_null", "output_is_null", "expected_result",
                                "expected_output_hex"}
                or not {"id", "input_values", "input_length", "output_capacity",
                        "expected_result", "expected_output_hex"}.issubset(case)):
            raise ValueError("fixture fields differ from the byte-output contract")
        values = case["input_values"]
        if (not isinstance(values, list) or type(case["input_length"]) is not int
                or case["input_length"] != len(values)
                or len(values) > MAX_PARSEABLE_INPUT_LENGTH
                or type(case["output_capacity"]) is not int
                or not 0 <= case["output_capacity"] <= MAX_OUTPUT_BYTES):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case["output_capacity"],
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        actual = contraction_oracle(values, **options)
        if actual != expected:
            raise ValueError(f"fixture differs from contraction oracle: {case['id']}")
        if not verify_certificate(values, expected[0], expected[1], **options):
            raise ValueError(f"fixture certificate is not feasible and optimal: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required in (TASK_URL, LIMITS_URL, "O(N^2)", "larger current component label",
                     "subset dynamic programming", "clean-room", "weighted ordering"):
        if required not in readme:
            raise ValueError(f"README is missing required contract text: {required}")
    if TASK_URL not in rights or LIMITS_URL not in rights or "Apache-2.0" not in rights:
        raise ValueError("rights and provenance notes are incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port link: {relative}")


if __name__ == "__main__":
    validate_package()
