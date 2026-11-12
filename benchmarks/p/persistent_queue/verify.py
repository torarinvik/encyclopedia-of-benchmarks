"""Static package checks and a separate direct queue-version model."""

from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from persistent_queue_oracle import (
    MAX_Q, MAX_VALUE, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_OUTPUT_BYTES, expected_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_queue/task.md"
SOURCE_PATHS = (
    "c/p/persistent_queue.c", "c3/p/persistent_queue.c3",
    "cpp/p/persistent_queue.cpp", "elisa/p/persistent_queue.elisa",
    "mojo/p/persistent_queue.mojo", "nim/p/persistent_queue.nim",
    "odin/p/persistent_queue.odin", "rust/p/persistent_queue.rs",
    "v/p/persistent_queue.v", "zig/p/persistent_queue.zig",
)
CASE_IDS = {
    "branch-and-pop-after-fork", "popping-sibling-versions-preserves-parent",
    "append-from-popped-version", "append-only-trace-has-no-output",
    "pop-empty-initial-version", "forward-parent-version", "value-out-of-range",
    "truncated-append", "trailing-word", "insufficient-output-capacity",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def direct_reference(values: list[int]) -> list[int] | None:
    """Parse the stream, copying a Python list for each persistent version."""
    if (len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    q = values[0]
    if not 1 <= q <= MAX_Q:
        return None
    versions: list[list[int]] = [[]]
    answers: list[int] = []
    cursor = 1
    for operation in range(q):
        if cursor + 2 > len(values):
            return None
        kind, parent = values[cursor:cursor + 2]
        cursor += 2
        if not -1 <= parent < operation:
            return None
        base = versions[parent + 1]
        if kind == 0:
            if cursor >= len(values):
                return None
            value = values[cursor]
            cursor += 1
            if not 0 <= value <= MAX_VALUE:
                return None
            versions.append(base + [value])
        elif kind == 1:
            if not base:
                return None
            answers.append(base[0])
            versions.append(base[1:])
        else:
            return None
    if cursor != len(values):
        return None
    return answers


def validate() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi",
        "description", "source", "input", "output", "workspace",
        "contract", "measurement", "cases",
    }, "workload fields differ from package schema")
    require(workload["schema_version"] == 1, "unsupported workload schema")
    require(workload["id"] == "library-checker-persistent-queue-bounded-i64-array-bytes-output-v1",
            "workload id mismatch")
    require(workload["algorithm"] == "persistent_queue", "algorithm mismatch")
    require(workload["function_symbol"] == "persistent_queue", "function symbol mismatch")
    require(workload["abi"] == "i64_array_bytes_output", "ABI mismatch")
    require(workload["source"] == {
        "title": "Persistent Queue",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker problem",
        "url": TASK_URL,
        "algorithm_attribution": "Persistent segment tree indexed by queue-relative append positions",
        "implementation_status": "clean-room bounded branching persistent queue profile",
    }, "source provenance mismatch")
    require(workload["input"] == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[Q, variable-length operations: opcode 0,parent,value or opcode 1,parent]",
        "Q_range": [1, MAX_Q],
        "parent_rule": "-1 <= parent < operation_index",
        "value_range": [0, MAX_VALUE],
        "pop_rule": "the selected parent version must be nonempty",
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload["output"] == {
        "kind": "byte_array",
        "encoding": "one signed 64-bit little-endian removed front value per opcode-1 operation, in operation order",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_capacity_result": -2,
        "output_untouched_on_error": True,
    }, "output contract mismatch")
    require(workload["workspace"] == {
        "bytes": MAX_OUTPUT_BYTES,
        "meaning": "Maximum output-buffer capacity; fixed persistent segment-tree nodes and version metadata use separate storage.",
    }, "workspace metadata mismatch")
    require(workload["contract"] == {
        "operation_0": "append value to the selected version and create the next version",
        "operation_1": "remove and return the selected version's front value, creating the next version",
        "initial_version": "version -1 is empty",
        "official_Q_maximum": 500000,
        "official_value_range": [0, 1000000000],
    }, "operation contract mismatch")
    require(workload["measurement"] == {
        "comparison_model": "i64_array_bytes_output_call",
        "sample_count": len(CASE_IDS),
        "warmup_rounds": 1,
        "repetitions_per_sample": 100,
    }, "measurement metadata mismatch")

    cases = workload["cases"]
    require({case.get("id") for case in cases} == CASE_IDS, "fixture IDs mismatch")
    for case in cases:
        values = case["input_values"]
        require(case["input_length"] == len(values), f"{case['id']}: input length mismatch")
        oracle_result, oracle_output = expected_output(values, case["output_capacity"])
        require(oracle_result == case["expected_result"], f"{case['id']}: oracle result mismatch")
        require(oracle_output.hex() == case["expected_output_hex"],
                f"{case['id']}: oracle bytes mismatch")
        direct = direct_reference(values)
        if direct is None:
            require(case["expected_result"] == -1,
                    f"{case['id']}: invalid direct-reference frame")
        else:
            direct_output = b"".join(struct.pack("<q", value) for value in direct)
            capacity = case["output_capacity"]
            if direct_output and capacity < len(direct_output):
                require(case["expected_result"] == -2 and not case["expected_output_hex"],
                        f"{case['id']}: direct-reference capacity mismatch")
            else:
                require(case["expected_result"] == len(direct_output),
                        f"{case['id']}: direct-reference result mismatch")
                require(case["expected_output_hex"] == direct_output.hex(),
                        f"{case['id']}: direct-reference output mismatch")

    maximum_input = [MAX_Q]
    for operation in range(MAX_Q):
        maximum_input.extend((0, -1, operation))
    result, output = expected_output(maximum_input, 0)
    require(len(maximum_input) == MAX_VALID_INPUT_LENGTH and result == 0 and not output,
            "maximum append trace has invalid framing or result")

    maximum_pop_input = [MAX_Q, 0, -1, 42]
    for _ in range(MAX_Q - 1):
        maximum_pop_input.extend((1, 0))
    result, output = expected_output(maximum_pop_input, MAX_OUTPUT_BYTES)
    require(result == MAX_OUTPUT_BYTES and output == struct.pack("<q", 42) * (MAX_Q - 1),
            "maximum branching-pop trace has invalid result or output")
    result, output = expected_output(maximum_pop_input, MAX_OUTPUT_BYTES - 1)
    require(result == -2 and not output, "maximum pop trace accepted short capacity")
    result, output = expected_output(maximum_pop_input, MAX_OUTPUT_BYTES, True)
    require(result == -2 and not output, "maximum pop trace accepted null output")

    for source in SOURCE_PATHS:
        source_file = ROOT / source
        require(source_file.is_file(), f"missing source: {source}")
        require("persistent_queue" in source_file.read_text(encoding="utf-8"),
                f"missing exported name in {source}")
    require((PACKAGE / "README.md").is_file(), "missing README")
    require((PACKAGE / "RIGHTS.md").is_file(), "missing rights note")
    require((ROOT / "benchmarks/persistent_queue_oracle.py").is_file(), "missing oracle")


if __name__ == "__main__":
    validate()
