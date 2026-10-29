"""Static workload, oracle, provenance, and nine-port path checks."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
from oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output  # noqa: E402

ALGORITHM = "static_range_mode_query"
ISSUE_URL = "https://github.com/yosupo06/library-checker-problems/issues/959"
PAPER_URL = "https://cs.au.dk/~larsen/papers/linear_mode.pdf"
SOURCE_PATHS = (
    "c/s/static_range_mode_query.c", "c3/s/static_range_mode_query.c3",
    "cpp/s/static_range_mode_query.cpp", "elisa/s/static_range_mode_query.elisa",
    "nim/s/static_range_mode_query.nim", "odin/s/static_range_mode_query.odin",
    "rust/s/static_range_mode_query.rs", "v/s/static_range_mode_query.v",
    "zig/s/static_range_mode_query.zig",
)
EXPECTED_CASE_IDS = {
    "single-element", "smallest-value-breaks-frequency-tie",
    "boundary-candidate-beats-block-mode", "whole-block-mode-tie",
    "range-with-no-whole-block", "four-mixed-ranges",
    "maximum-array-and-query-batch", "n-out-of-range", "q-out-of-range",
    "value-out-of-range", "empty-range-invalid", "range-end-out-of-range",
    "truncated-query-frame", "trailing-input-value", "null-output",
    "short-output-capacity", "null-input",
}


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_contract = {
        "operation": "For each half-open static array range, return a mode and its frequency.",
        "input_layout": "[n, q, A_0, ..., A_(n-1), (l, r)*q]",
        "n_range": [1, 32], "q_range": [1, 16],
        "value_range": [0, 1000000000], "query_range": "0 <= l < r <= n",
        "tie_rule": "Choose the smallest numeric value among modes.",
        "output_encoding": "For each query, little-endian signed i64 (mode, frequency).",
        "success_result": "16*q bytes written", "invalid_input_result": -1,
        "null_output_result": -2, "insufficient_output_capacity_result": -2,
        "no_write_on_error": True,
    }
    expected_input = {
        "kind": "signed_64_bit_integer_array", "maximum_valid_length": MAX_INPUT_LENGTH,
        "maximum_parseable_length": MAX_INPUT_LENGTH, "invalid_result": -1,
        "null_input_result": -1,
    }
    expected_output = {
        "kind": "little_endian_signed_64_bit_pairs", "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "16*q bytes", "invalid_input_result": -1,
        "null_output_result": -2, "insufficient_output_capacity_result": -2,
        "no_write_on_error": True,
    }
    if (set(workload) != {
                "schema_version", "id", "algorithm", "function_symbol", "abi", "source",
                "contract", "input", "output", "workspace", "measurement", "cases"}
            or workload.get("schema_version") != 1
            or workload.get("id") != "static-range-mode-query-bounded-v1"
            or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source") != {
                "name": "Library Checker Static Range Mode Query proposal",
                "url": ISSUE_URL, "algorithm_reference": PAPER_URL,
                "reuse": "Problem taxonomy and algorithm reference only; no source code or prose copied.",
            }
            or workload.get("contract") != expected_contract
            or workload.get("input") != expected_input
            or workload.get("output") != expected_output
            or workload.get("workspace") != {
                "bytes": 4096,
                "meaning": "Rank compression, occurrence positions, and the bounded block-mode table.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i64_array_bytes_output_call",
                "sample_count": 5, "warmup_rounds": 1, "repetitions_per_sample": 100,
            }):
        raise ValueError("workload metadata differs from its bounded contract")
    cases = workload.get("cases")
    if (not isinstance(cases, list)
            or {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASE_IDS
            or len(cases) != len(EXPECTED_CASE_IDS)):
        raise ValueError("workload has missing, duplicate, or unexpected fixtures")
    ids = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in ids:
            raise ValueError(f"duplicate fixture id: {case['id']}")
        ids.add(case["id"])
        values = case.get("input_values")
        result, output = expected_output(
            values, case.get("output_capacity"), case.get("output_is_null", False),
            case.get("input_is_null", False), case.get("input_length"))
        if case.get("expected_result") != result or case.get("expected_output_hex") != output.hex():
            raise ValueError(f"fixture differs from direct-scan oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if (ISSUE_URL not in readme or PAPER_URL not in readme
            or "O(n^2 + n*ceil(n/B) + q*B*log n)" not in readme
            or "smallest mode value" not in readme):
        raise ValueError("README is missing provenance, complexity, or tie-rule documentation")
    for relative in SOURCE_PATHS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"missing source port or exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing source link: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"validated {verify_workload()} fixtures and {len(SOURCE_PATHS)} source paths")
