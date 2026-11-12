"""Static metadata, fixture, and source-presence checks for this package."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from range_affine_point_get_oracle import (
    MAX_N, MAX_Q, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_OUTPUT_BYTES, expected_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_affine_point_get/task.md"
SOURCE_PATHS = (
    "c/r/range_affine_point_get.c", "c3/r/range_affine_point_get.c3",
    "cpp/r/range_affine_point_get.cpp", "elisa/r/range_affine_point_get.elisa",
    "mojo/r/range_affine_point_get.mojo", "nim/r/range_affine_point_get.nim",
    "odin/r/range_affine_point_get.odin", "rust/r/range_affine_point_get.rs",
    "v/r/range_affine_point_get.v", "zig/r/range_affine_point_get.zig",
)
CASE_IDS = {
    "overlapping-affine-updates-and-point-reads",
    "nested-range-composition-order", "single-element-affine-composition",
    "empty-operation-stream", "invalid-empty-range",
    "invalid-zero-multiplier", "truncated-point-query", "trailing-input-value",
    "insufficient-output-capacity",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text())
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi",
        "description", "source", "input", "output", "workspace",
        "contract", "measurement", "cases",
    }, "workload fields differ from the package schema")
    require(workload["schema_version"] == 1, "unsupported workload schema")
    require(workload["id"] == "library-checker-range-affine-point-get-bounded-i64-array-bytes-output-v1",
            "workload id mismatch")
    require(workload["algorithm"] == "range_affine_point_get", "algorithm mismatch")
    require(workload["function_symbol"] == "range_affine_point_get", "function symbol mismatch")
    require(workload["abi"] == "i64_array_bytes_output", "ABI mismatch")
    require(workload["source"] == {
        "title": "Range Affine Point Get",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker problem",
        "url": TASK_URL,
        "algorithm_attribution": "Lazy segment tree with chronological affine-tag composition",
        "implementation_status": "clean-room bounded range-update/point-query profile",
    }, "source provenance mismatch")
    require(workload["input"] == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,Q,initial_values...,variable-length operations...]",
        "N_range": [1, MAX_N], "Q_range": [0, MAX_Q],
        "modulus": 998244353,
        "initial_value_range": [0, 998244352],
        "multiplier_range": [1, 998244352],
        "offset_range": [0, 998244352],
        "operation_0": "opcode 0 followed by left,right,multiplier,offset",
        "operation_1": "opcode 1 followed by index",
        "range_rule": "0 <= left < right <= N", "index_rule": "0 <= index < N",
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload["output"] == {
        "kind": "byte_array",
        "encoding": "one signed 64-bit little-endian point value per type-1 operation, in operation order",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written", "invalid_input_result": -1,
        "null_output_result": -2, "insufficient_capacity_result": -2,
        "output_untouched_on_error": True,
    }, "output contract mismatch")
    require(workload["workspace"] == {
        "bytes": MAX_OUTPUT_BYTES,
        "meaning": "Maximum output-buffer capacity; the padded segment-tree tag arrays are separate fixed storage.",
    }, "workspace metadata mismatch")
    require(workload["contract"] == {
        "operation_0": "apply x -> multiplier*x + offset modulo 998244353 to every index in [left,right)",
        "operation_1": "return the current value at index modulo 998244353",
        "official_N_and_Q_maximum": 500000, "official_modulus": 998244353,
    }, "operation contract mismatch")
    require(workload["measurement"] == {
        "comparison_model": "i64_array_bytes_output_call", "sample_count": len(CASE_IDS),
        "warmup_rounds": 1, "repetitions_per_sample": 100,
    }, "measurement metadata mismatch")
    cases = workload["cases"]
    require({case.get("id") for case in cases} == CASE_IDS, "fixture IDs mismatch")
    for case in cases:
        values = case["input_values"]
        require(case["input_length"] == len(values), f"{case['id']}: input length mismatch")
        result, output = expected_output(values, case["output_capacity"])
        require(result == case["expected_result"], f"{case['id']}: expected result mismatch")
        require(output.hex() == case["expected_output_hex"], f"{case['id']}: expected bytes mismatch")
    for source in SOURCE_PATHS:
        source_file = ROOT / source
        require(source_file.is_file(), f"missing language source: {source}")
        require("range_affine_point_get" in source_file.read_text(),
                f"missing exported symbol/name in {source}")
    require((ROOT / "benchmarks/r/range_affine_point_get/README.md").is_file(), "missing README")
    require((ROOT / "benchmarks/r/range_affine_point_get/RIGHTS.md").is_file(), "missing rights note")
    require((ROOT / "benchmarks/range_affine_point_get_oracle.py").is_file(), "missing oracle")


if __name__ == "__main__":
    validate()
