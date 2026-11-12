"""Static package metadata and direct-reference fixture checks."""

from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from point_set_range_frequency_oracle import (
    MAX_N, MAX_Q, MAX_VALUE, MAX_VALID_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/point_set_range_frequency/task.md"
SOURCE_PATHS = (
    "c/p/point_set_range_frequency.c", "c3/p/point_set_range_frequency.c3",
    "cpp/p/point_set_range_frequency.cpp", "elisa/p/point_set_range_frequency.elisa",
    "mojo/p/point_set_range_frequency.mojo", "nim/p/point_set_range_frequency.nim",
    "odin/p/point_set_range_frequency.odin", "rust/p/point_set_range_frequency.rs",
    "v/p/point_set_range_frequency.v", "zig/p/point_set_range_frequency.zig",
)
CASE_IDS = {
    "duplicate-values-updates-and-empty-range", "same-value-assignment-and-absent-value",
    "query-value-not-in-compressed-universe", "empty-operation-stream",
    "invalid-point-index", "invalid-reversed-range", "truncated-point-assignment",
    "trailing-input-value", "insufficient-output-capacity",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def direct_reference(values: list[int]) -> list[int] | None:
    """Parse and answer with direct array assignment and range scans."""
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    cursor = 2
    if cursor + n > len(values):
        return None
    current = list(values[cursor:cursor + n])
    cursor += n
    if any(not 0 <= value <= MAX_VALUE for value in current):
        return None
    operations: list[tuple[int, ...]] = []
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 2 > len(values):
                return None
            index, value = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= index < n or not 0 <= value <= MAX_VALUE:
                return None
            operations.append((0, index, value))
        elif kind == 1:
            if cursor + 3 > len(values):
                return None
            left, right, value = values[cursor:cursor + 3]
            cursor += 3
            if not 0 <= left <= right <= n or not 0 <= value <= MAX_VALUE:
                return None
            operations.append((1, left, right, value))
        else:
            return None
    if cursor != len(values):
        return None
    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, index, value = operation
            current[index] = value
        else:
            _, left, right, value = operation
            count = 0
            for index in range(left, right):
                if current[index] == value:
                    count += 1
            answers.append(count)
    return answers


def validate() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text())
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi",
        "description", "source", "input", "output", "workspace",
        "contract", "measurement", "cases",
    }, "workload fields differ from package schema")
    require(workload["schema_version"] == 1, "unsupported workload schema")
    require(workload["id"] == "library-checker-point-set-range-frequency-bounded-i64-array-bytes-output-v1",
            "workload id mismatch")
    require(workload["algorithm"] == "point_set_range_frequency", "algorithm mismatch")
    require(workload["function_symbol"] == "point_set_range_frequency", "function symbol mismatch")
    require(workload["abi"] == "i64_array_bytes_output", "ABI mismatch")
    require(workload["source"] == {
        "title": "Point Set Range Frequency",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker problem",
        "url": TASK_URL,
        "algorithm_attribution": "Offline-compressed value-indexed Fenwick trees over positions",
        "implementation_status": "clean-room bounded point-set/range-frequency profile",
    }, "source provenance mismatch")
    require(workload["input"] == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,Q,initial_values...,variable_length_operations]",
        "N_range": [1, MAX_N], "Q_range": [0, MAX_Q],
        "value_range": [0, MAX_VALUE],
        "operation_0": "opcode 0 followed by index,value",
        "operation_1": "opcode 1 followed by left,right,value",
        "index_rule": "0 <= index < N", "range_rule": "0 <= left <= right <= N",
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload["output"] == {
        "kind": "byte_array",
        "encoding": "one signed 64-bit little-endian exact-value frequency per type-1 operation, in operation order",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written", "invalid_input_result": -1,
        "null_output_result": -2, "insufficient_capacity_result": -2,
        "output_untouched_on_error": True,
    }, "output contract mismatch")
    require(workload["workspace"] == {
        "bytes": MAX_OUTPUT_BYTES,
        "meaning": "Maximum output-buffer capacity; compressed-value Fenwick tables use separate fixed storage.",
    }, "workspace metadata mismatch")
    require(workload["contract"] == {
        "operation_0": "assign value at index",
        "operation_1": "count positions with the requested value in the half-open range [left,right)",
        "official_N_and_Q_maximum": 200000,
        "official_value_maximum": 1000000000,
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
        oracle_result, oracle_output = expected_output(values, case["output_capacity"])
        require(oracle_result == case["expected_result"], f"{case['id']}: oracle result mismatch")
        require(oracle_output.hex() == case["expected_output_hex"], f"{case['id']}: oracle bytes mismatch")
        direct = direct_reference(values)
        if direct is None:
            require(case["expected_result"] == -1, f"{case['id']}: invalid direct-reference frame")
        else:
            direct_output = b"".join(struct.pack("<q", count) for count in direct)
            needed = len(direct_output)
            if needed > case["output_capacity"] and needed > 0:
                require(case["expected_result"] == -2 and case["expected_output_hex"] == "",
                        f"{case['id']}: direct-reference capacity mismatch")
            else:
                require(case["expected_result"] == needed, f"{case['id']}: direct-reference result mismatch")
                require(case["expected_output_hex"] == direct_output.hex(),
                        f"{case['id']}: direct-reference output mismatch")
    for source in SOURCE_PATHS:
        source_file = ROOT / source
        require(source_file.is_file(), f"missing source: {source}")
        require("point_set_range_frequency" in source_file.read_text(),
                f"missing exported name in {source}")
    require((PACKAGE / "README.md").is_file(), "missing README")
    require((PACKAGE / "RIGHTS.md").is_file(), "missing rights note")
    require((ROOT / "benchmarks/point_set_range_frequency_oracle.py").is_file(), "missing oracle")


if __name__ == "__main__":
    validate()
