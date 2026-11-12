#!/usr/bin/env python3
"""Statically verify the bounded rectangle-add/point-get package."""

from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

from rectangle_add_point_get_oracle import (
    MAX_N, MAX_Q, MAX_COORD, MAX_WEIGHT, MAX_VALID_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output,
)

ROOT = Path(__file__).resolve().parents[1]
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/rectangle_add_point_get/task.md"
SOURCE_PATHS = (
    "c/r/rectangle_add_point_get.c", "c3/r/rectangle_add_point_get.c3",
    "cpp/r/rectangle_add_point_get.cpp", "elisa/r/rectangle_add_point_get.elisa",
    "mojo/r/rectangle_add_point_get.mojo", "nim/r/rectangle_add_point_get.nim",
    "odin/r/rectangle_add_point_get.odin", "rust/r/rectangle_add_point_get.rs",
    "v/r/rectangle_add_point_get.v", "zig/r/rectangle_add_point_get.zig",
)
CASE_IDS = {
    "overlap-add-and-point-queries", "half-open-rectangle-edges",
    "zero-weight-and-upper-coordinate", "empty-point-query-stream",
    "invalid-degenerate-initial-rectangle",
    "truncated-rectangle-add", "invalid-point-coordinate",
    "insufficient-output-capacity",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def direct_reference(values: list[int]) -> list[int] | None:
    """Parse and answer by scanning the current rectangle list at each query."""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values) or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    cursor = 2
    rectangles: list[tuple[int, int, int, int, int]] = []
    for _ in range(n):
        if cursor + 5 > len(values):
            return None
        left, down, right, up, weight = values[cursor:cursor + 5]
        cursor += 5
        if not (0 <= left < right <= MAX_COORD
                and 0 <= down < up <= MAX_COORD
                and 0 <= weight <= MAX_WEIGHT):
            return None
        rectangles.append((left, down, right, up, weight))

    operations: list[tuple[int, ...]] = []
    for _ in range(q):
        if cursor >= len(values):
            return None
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if cursor + 5 > len(values):
                return None
            left, down, right, up, weight = values[cursor:cursor + 5]
            cursor += 5
            if not (0 <= left < right <= MAX_COORD
                    and 0 <= down < up <= MAX_COORD
                    and 0 <= weight <= MAX_WEIGHT):
                return None
            operations.append((0, left, down, right, up, weight))
        elif opcode == 1:
            if cursor + 2 > len(values):
                return None
            x, y = values[cursor:cursor + 2]
            cursor += 2
            if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD):
                return None
            operations.append((1, x, y))
        else:
            return None
    if cursor != len(values):
        return None

    answers = []
    for operation in operations:
        if operation[0] == 0:
            rectangles.append(operation[1:])
            continue
        x, y = operation[1:]
        total = 0
        for left, down, right, up, weight in rectangles:
            if left <= x < right and down <= y < up:
                total += weight
        answers.append(total)
    return answers


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(set(workload) == {
        "schema_version", "id", "algorithm", "function_symbol", "abi",
        "description", "source", "input", "output", "workspace",
        "contract", "measurement", "cases",
    }, "workload fields differ from the bounded package schema")
    require(workload["schema_version"] == 1, "unsupported workload schema")
    require(workload["id"] == "library-checker-rectangle-add-point-get-bounded-i64-array-bytes-output-v1",
            "workload id mismatch")
    require(workload["algorithm"] == "rectangle_add_point_get", "algorithm name mismatch")
    require(workload["function_symbol"] == "rectangle_add_point_get", "function symbol mismatch")
    require(workload["abi"] == "i64_array_bytes_output", "ABI mismatch")
    require(workload["source"] == {
        "title": "Rectangle Add Point Get",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker problem",
        "url": TASK_URL,
        "algorithm_attribution": "Four-corner 2D difference updates with an offline compressed Fenwick tree of Fenwick trees",
        "implementation_status": "clean-room bounded dynamic rectangle profile",
    }, "source provenance mismatch")
    require(workload["input"] == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,Q,(left,down,right,up,weight)*N,variable-length operations]",
        "N_range": [1, MAX_N], "Q_range": [1, MAX_Q],
        "coordinate_range": [0, MAX_COORD], "weight_range": [0, MAX_WEIGHT],
        "operation_0": "opcode 0 followed by left,down,right,up,weight",
        "operation_1": "opcode 1 followed by x,y",
        "rectangle_rule": "0 <= left < right <= 1000000 and 0 <= down < up <= 1000000",
        "point_rule": "0 <= x,y <= 1000000",
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload["output"] == {
        "kind": "byte_array",
        "encoding": "one signed 64-bit little-endian sum of containing rectangle weights per point query, in operation order",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_capacity_result": -2,
        "output_untouched_on_error": True,
    }, "output contract mismatch")
    require(workload["workspace"] == {
        "bytes": MAX_OUTPUT_BYTES,
        "meaning": "Maximum output-buffer capacity; compressed coordinate and nested Fenwick tables are separate fixed arrays.",
    }, "workspace metadata mismatch")
    require(workload["contract"] == {
        "initial_rectangle_semantics": "each initial rectangle contributes its weight independently, including duplicate rectangles",
        "operation_0": "append a rectangle with the given weight",
        "operation_1": "sum weights of rectangles containing the point, using half-open rectangle bounds",
        "official_N_and_Q_range": [1, 100000],
        "official_coordinate_and_weight_maximum": 1000000000,
    }, "operation contract mismatch")
    require(workload["measurement"] == {
        "comparison_model": "i64_array_bytes_output_call",
        "sample_count": len(CASE_IDS), "warmup_rounds": 1, "repetitions_per_sample": 100,
    }, "measurement metadata mismatch")

    cases = workload["cases"]
    require(isinstance(cases, list), "workload cases must be an array")
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    require(len(ids) == len(cases) and len(set(ids)) == len(ids), "fixture IDs must be unique")
    require(set(ids) == CASE_IDS, "fixture set mismatch")
    for case in cases:
        case_id = case["id"]
        require(set(case) <= {
            "id", "input_values", "input_length", "output_capacity",
            "output_is_null", "input_is_null", "expected_result", "expected_output_hex",
        } and {
            "id", "input_values", "input_length", "output_capacity",
            "expected_result", "expected_output_hex",
        }.issubset(case), f"{case_id}: fixture fields mismatch")
        values = case["input_values"]
        input_length = case["input_length"]
        capacity = case["output_capacity"]
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        require(isinstance(values, list), f"{case_id}: input values must be a list")
        require(type(input_length) is int and input_length == len(values),
                f"{case_id}: input framing mismatch")
        require(type(capacity) is int and 0 <= capacity <= MAX_OUTPUT_BYTES,
                f"{case_id}: output capacity out of range")
        require(type(output_is_null) is bool and type(input_is_null) is bool,
                f"{case_id}: null flags must be booleans")
        require(type(case["expected_result"]) is int
                and isinstance(case["expected_output_hex"], str),
                f"{case_id}: expected output fields have invalid types")
        require(not input_is_null, f"{case_id}: unexpected null-input fixture")
        answers = direct_reference(values)
        if answers is None:
            direct_result, direct_payload = -1, b""
        else:
            direct_payload = b"".join(struct.pack("<q", answer) for answer in answers)
            if direct_payload and (output_is_null or capacity < len(direct_payload)):
                direct_result, direct_payload = -2, b""
            else:
                direct_result = len(direct_payload)
        oracle_result, oracle_payload = expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        require((oracle_result, oracle_payload) == (direct_result, direct_payload),
                f"{case_id}: direct verifier and package oracle disagree")
        require(case.get("expected_result") == direct_result,
                f"{case_id}: expected result mismatch")
        require(case.get("expected_output_hex") == direct_payload.hex(),
                f"{case_id}: expected output mismatch")

    initial_rectangles = tuple(
        field for index in range(MAX_N)
        for field in (index, index, index + 1, index + 1, 0)
    )
    maximum_updates = tuple(
        field for index in range(MAX_Q)
        for field in (0, 100 + index, 200 + index, 101 + index, 201 + index, 1)
    )
    max_update_profile = (MAX_N, MAX_Q, *initial_rectangles, *maximum_updates)
    require(len(max_update_profile) == MAX_VALID_INPUT_LENGTH,
            "maximum rectangle-update profile has an invalid length")
    require(direct_reference(list(max_update_profile)) == [],
            "maximum rectangle-update profile should contain no point queries")
    result, payload = expected_output(max_update_profile, 0, True)
    require((result, payload) == (0, b""),
            "zero-output maximum profile rejected a null output buffer")

    maximum_queries = tuple(
        field for index in range(MAX_Q) for field in (1, index, index)
    )
    max_query_profile = (MAX_N, MAX_Q, *initial_rectangles, *maximum_queries)
    require(len(max_query_profile) == 2 + 5 * MAX_N + 3 * MAX_Q,
            "maximum point-query profile has an invalid length")
    require(direct_reference(list(max_query_profile)) == [0] * MAX_Q,
            "maximum point-query profile has an invalid direct result")
    result, payload = expected_output(max_query_profile, MAX_OUTPUT_BYTES)
    require(result == MAX_OUTPUT_BYTES and payload == bytes(MAX_OUTPUT_BYTES),
            "maximum point-query profile has an invalid encoded result")


def validate_sources() -> None:
    readme = (ROOT / "benchmarks/r/rectangle_add_point_get/README.md").read_text(
        encoding="utf-8")
    require(TASK_URL in readme, "README is missing official task provenance")
    require("O(log^2 P)" in readme and "directly" in readme.lower(),
            "README is missing the complexity or independent-oracle description")
    for relative in SOURCE_PATHS:
        source = ROOT / relative
        require(source.is_file(), f"missing source file {relative}")
        require(relative in readme, f"README is missing the source link: {relative}")
        require("rectangle_add_point_get" in source.read_text(encoding="utf-8"),
                f"source is missing the exported symbol: {relative}")


def main() -> int:
    package = ROOT / "benchmarks/r/rectangle_add_point_get"
    workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = (package / "README.md").read_text(encoding="utf-8")
    require(TASK_URL in readme, "README is missing official task provenance")
    require("O(log^2 P)" in readme and "directly" in readme.lower(),
            "README is missing the complexity or independent-oracle description")
    for relative in SOURCE_PATHS:
        require(relative in readme, f"README is missing the source link: {relative}")
    print("rectangle_add_point_get package contract, fixtures, and ten source paths checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL rectangle_add_point_get static verification: {error}", file=sys.stderr)
        raise SystemExit(1)
