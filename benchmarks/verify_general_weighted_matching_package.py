"""Static metadata, source, fixture, and certificate checks for the package.

The checker is added for later explicit verification and is not run during
source-only package work.
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

from general_weighted_matching_oracle import (
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_WEIGHT,
    expected_output as bitmask_dp_oracle,
)
from general_weighted_matching_checker import (
    expected_output as recursive_matching_checker,
)


ROOT = Path(__file__).resolve().parent.parent
PACKAGE = ROOT / "benchmarks" / "g" / "general_weighted_matching"
ALGORITHM = "general_weighted_matching"
TASK_URL = (
    "https://raw.githubusercontent.com/yosupo06/library-checker-problems/"
    "master/graph/general_weighted_matching/task.md"
)
LIMITS_URL = (
    "https://raw.githubusercontent.com/yosupo06/library-checker-problems/"
    "master/graph/general_weighted_matching/info.toml"
)
PORTS = (
    "c/g/general_weighted_matching.c",
    "c3/g/general_weighted_matching.c3",
    "cpp/g/general_weighted_matching.cpp",
    "elisa/g/general_weighted_matching.elisa",
    "mojo/g/general_weighted_matching.mojo",
    "nim/g/general_weighted_matching.nim",
    "odin/g/general_weighted_matching.odin",
    "rust/g/general_weighted_matching.rs",
    "v/g/general_weighted_matching.v",
    "zig/g/general_weighted_matching.zig",
)
CASE_IDS = {
    "single-vertex-empty-matching",
    "empty-four-vertex-graph",
    "weighted-choice-beats-cardinality",
    "odd-cycle-maximum-weight",
    "cycle-deterministic-tie",
    "reversed-duplicate-edge-is-invalid",
    "self-loop-is-invalid",
    "zero-edge-weight-is-invalid",
    "weight-above-local-bound-is-invalid",
    "truncated-edge-record",
    "vertex-limit-is-enforced",
    "trailing-word-is-invalid",
    "insufficient-output-capacity",
    "null-output-buffer",
}


def _verify_certificate(values: list[int], payload: bytes) -> None:
    words = struct.unpack("<" + "q" * (len(payload) // 8), payload)
    if len(words) < 2:
        raise ValueError("matching certificate omits its size and weight")
    pair_count, total_weight = words[:2]
    if (type(pair_count) is not int or pair_count < 0
            or len(words) != 2 + 2 * pair_count):
        raise ValueError("matching certificate word count is inconsistent")
    n, m = values[:2]
    edge_weights: dict[tuple[int, int], int] = {}
    for index in range(m):
        u, v, weight = values[2 + 3 * index:5 + 3 * index]
        edge_weights[min(u, v), max(u, v)] = weight
    pairs = [(words[2 + 2 * i], words[3 + 2 * i]) for i in range(pair_count)]
    if pairs != sorted(pairs):
        raise ValueError("matching certificate pairs are not in canonical order")
    used: set[int] = set()
    measured_weight = 0
    for u, v in pairs:
        if (not 0 <= u < v < n or u in used or v in used
                or (u, v) not in edge_weights):
            raise ValueError("matching certificate contains an invalid or repeated edge")
        used.add(u)
        used.add(v)
        measured_weight += edge_weights[u, v]
    if measured_weight != total_weight:
        raise ValueError("matching certificate total differs from its edge weights")


def validate_package() -> None:
    if (MAX_N, MAX_WEIGHT, MAX_VALID_INPUT_LENGTH,
            MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES) != (16, 1_000_000, 362, 363, 144):
        raise ValueError("oracle constants differ from the bounded profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_source = {
        "title": "General Weighted Matching",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker task contract; local profile uses clean-room bitmask DP",
        "url": TASK_URL,
        "limits_url": LIMITS_URL,
        "algorithm_attribution": "Exact maximum-weight matching by unmatched-or-paired subset recurrence",
        "implementation_status": "clean-room bounded profile",
    }
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,M,u0,v0,w0,...] with one triple per undirected edge",
        "N_range": [1, MAX_N],
        "M_range": "0 <= M <= N*(N-1)/2",
        "weight_range": [1, MAX_WEIGHT],
        "edge_rule": "simple undirected graph; endpoint order is arbitrary; self-loops and duplicate unordered pairs are invalid",
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "byte_array",
        "encoding": "little-endian signed 64-bit words [matching_size,total_weight,u0,v0,...] with normalized pairs in deterministic order",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_capacity_result": -2,
        "output_untouched_on_error": True,
    }
    expected_contract = {
        "objective": "maximize the sum of weights of a set of pairwise vertex-disjoint edges; an empty matching is allowed",
        "official_N_range": [1, 500],
        "official_M_range": "0 <= M <= N*(N-1)/2",
        "official_weight_range": [1, 1_000_000],
        "certificate": "matching size, total weight, followed by matched endpoint pairs",
    }
    cases = workload.get("cases")
    if workload != {
        "schema_version": 1,
        "id": "library-checker-general-weighted-matching-bounded-i64-array-bytes-output-v1",
        "algorithm": ALGORITHM,
        "function_symbol": ALGORITHM,
        "abi": "i64_array_bytes_output",
        "description": "Maximum-total-weight matching in a bounded simple undirected graph by exact bitmask dynamic programming.",
        "source": expected_source,
        "input": expected_input,
        "output": expected_output,
        "workspace": {
            "bytes": MAX_OUTPUT_BYTES,
            "meaning": "Maximum output-buffer capacity; graph and 2^N DP storage are separate bounded memory.",
        },
        "contract": expected_contract,
        "measurement": {
            "comparison_model": "i64_array_bytes_output_call",
            "sample_count": 6,
            "warmup_rounds": 1,
            "repetitions_per_sample": 100,
        },
        "cases": cases,
    }:
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
        primary = bitmask_dp_oracle(values, **options)
        independent = recursive_matching_checker(values, **options)
        if primary != expected or independent != expected:
            raise ValueError(f"fixture differs from one of the two oracles: {case['id']}")
        if primary[0] >= 0:
            _verify_certificate(values, primary[1])

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required in (TASK_URL, LIMITS_URL, "O(N 2^N)", "maximum total weight",
                     "general_graph_maximum_matching", "clean-room", "bitmask"):
        if required not in readme:
            raise ValueError(f"README is missing required contract or distinctness text: {required}")
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
