"""Static package metadata checks with a direct mutable-point-list model."""

from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from dynamic_point_set_rectangle_affine_rectangle_sum_oracle import (
    MAX_N, MAX_Q, MAX_COORD, MOD, MAX_VALID_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/dynamic_point_set_rectangle_affine_rectangle_sum/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/dynamic_point_set_rectangle_affine_rectangle_sum/info.toml"
SOURCE_PATHS = (
    "c/d/dynamic_point_set_rectangle_affine_rectangle_sum.c",
    "c3/d/dynamic_point_set_rectangle_affine_rectangle_sum.c3",
    "cpp/d/dynamic_point_set_rectangle_affine_rectangle_sum.cpp",
    "elisa/d/dynamic_point_set_rectangle_affine_rectangle_sum.elisa",
    "mojo/d/dynamic_point_set_rectangle_affine_rectangle_sum.mojo",
    "nim/d/dynamic_point_set_rectangle_affine_rectangle_sum.nim",
    "odin/d/dynamic_point_set_rectangle_affine_rectangle_sum.odin",
    "rust/d/dynamic_point_set_rectangle_affine_rectangle_sum.rs",
    "v/d/dynamic_point_set_rectangle_affine_rectangle_sum.v",
    "zig/d/dynamic_point_set_rectangle_affine_rectangle_sum.zig",
)
CASE_IDS = {
    "duplicate-points-point-set-and-affine-rectangle",
    "pre-insertion-affine-does-not-change-new-point",
    "upper-exclusive-maximum-coordinate", "point-set-only-zero-output",
    "point-index-not-yet-present", "reversed-rectangle",
    "truncated-affine-operation", "trailing-input-word",
    "insufficient-output-capacity",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def direct_reference(values: list[int]) -> list[int] | None:
    """Validate and execute by updating a plain list and scanning rectangles."""
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or 2 + 3 * n > len(values):
        return None
    points = []
    for index in range(n):
        x, y, weight = values[2 + 3 * index:5 + 3 * index]
        if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD and 0 <= weight < MOD):
            return None
        points.append([x, y, weight])

    answers = []
    cursor = 2 + 3 * n
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 3 > len(values):
                return None
            x, y, weight = values[cursor:cursor + 3]
            cursor += 3
            if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD and 0 <= weight < MOD):
                return None
            points.append([x, y, weight])
        elif kind == 1:
            if cursor + 2 > len(values):
                return None
            point_id, weight = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= point_id < len(points) or not 0 <= weight < MOD:
                return None
            points[point_id][2] = weight
        elif kind in (2, 3):
            operand_count = 4 if kind == 2 else 6
            if cursor + operand_count > len(values):
                return None
            left, down, right, up = values[cursor:cursor + 4]
            if not (0 <= left < right <= MAX_COORD and 0 <= down < up <= MAX_COORD):
                return None
            if kind == 2:
                cursor += 4
                answers.append(sum(point[2] for point in points
                                   if left <= point[0] < right and down <= point[1] < up) % MOD)
            else:
                a, b = values[cursor + 4:cursor + 6]
                cursor += 6
                if not 0 <= a < MOD or not 0 <= b < MOD:
                    return None
                for point in points:
                    if left <= point[0] < right and down <= point[1] < up:
                        point[2] = (a * point[2] + b) % MOD
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
    require(workload["id"] == "library-checker-dynamic-point-set-rectangle-affine-rectangle-sum-bounded-i64-array-bytes-output-v1",
            "workload id mismatch")
    require(workload["algorithm"] == "dynamic_point_set_rectangle_affine_rectangle_sum",
            "algorithm mismatch")
    require(workload["function_symbol"] == "dynamic_point_set_rectangle_affine_rectangle_sum",
            "function symbol mismatch")
    require(workload["abi"] == "i64_array_bytes_output", "ABI mismatch")
    require(workload["source"] == {
        "title": "Dynamic Point Rectangle Affine Rectangle Sum",
        "authors": ["Library Checker contributors"],
        "reference": "Library Checker problem",
        "url": TASK_URL,
        "limits_url": LIMITS_URL,
        "algorithm_attribution": "Offline-built balanced k-d tree with active leaves and lazy affine tags",
        "implementation_status": "clean-room bounded dynamic point-set profile",
    }, "source provenance mismatch")
    require(workload["input"] == {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,Q,initial_points...,variable_length_operations]",
        "N_range": [1, MAX_N], "Q_range": [1, MAX_Q],
        "coordinate_range": [0, MAX_COORD], "modulus": MOD,
        "initial_point": "x,y,w",
        "operation_0": "opcode 0 followed by x,y,w; append a separate point",
        "operation_1": "opcode 1 followed by point_id,w; assign its weight",
        "operation_2": "opcode 2 followed by left,down,right,up; query half-open rectangle sum",
        "operation_3": "opcode 3 followed by left,down,right,up,a,b; apply w <- a*w+b",
        "weight_and_affine_range": [0, MOD - 1],
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "invalid_input_result": -1,
    }, "input contract mismatch")
    require(workload["output"] == {
        "kind": "byte_array",
        "encoding": "one signed 64-bit little-endian residue per type-2 query, in operation order",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written",
        "invalid_input_result": -1, "null_output_result": -2,
        "insufficient_capacity_result": -2, "output_untouched_on_error": True,
    }, "output contract mismatch")
    require(workload["workspace"] == {
        "bytes": MAX_OUTPUT_BYTES,
        "meaning": "Maximum output-buffer capacity; the bounded k-d tree and operation arrays use separate fixed storage.",
    }, "workspace metadata mismatch")
    require(workload["contract"] == {
        "initial_version": "initial points are active before the first operation",
        "append_semantics": "each type-0 operation appends a distinct point at its coordinates and starts with its supplied weight",
        "rectangle_semantics": "all rectangle bounds are half-open; only points already appended participate",
        "affine_order": "w <- a*w+b modulo 998244353",
        "official_N_maximum": 100000, "official_Q_maximum": 100000,
        "official_coordinate_maximum": 1000000000, "official_modulus": MOD,
    }, "operation contract mismatch")
    require(workload["measurement"] == {
        "comparison_model": "i64_array_bytes_output_call",
        "sample_count": len(CASE_IDS), "warmup_rounds": 1,
        "repetitions_per_sample": 100,
    }, "measurement metadata mismatch")

    cases = workload["cases"]
    require({case.get("id") for case in cases} == CASE_IDS, "fixture IDs mismatch")
    for case in cases:
        values = case["input_values"]
        require(case["input_length"] == len(values), f"{case['id']}: input length mismatch")
        result, output = expected_output(values, case["output_capacity"])
        require(result == case["expected_result"], f"{case['id']}: oracle result mismatch")
        require(output.hex() == case["expected_output_hex"], f"{case['id']}: oracle bytes mismatch")
        reference = direct_reference(values)
        if reference is None:
            require(case["expected_result"] == -1, f"{case['id']}: invalid direct frame")
        else:
            direct_output = b"".join(struct.pack("<q", value) for value in reference)
            capacity = case["output_capacity"]
            if direct_output and capacity < len(direct_output):
                require(case["expected_result"] == -2 and not case["expected_output_hex"],
                        f"{case['id']}: direct capacity mismatch")
            else:
                require(case["expected_result"] == len(direct_output),
                        f"{case['id']}: direct result mismatch")
                require(case["expected_output_hex"] == direct_output.hex(),
                        f"{case['id']}: direct output mismatch")

    for source in SOURCE_PATHS:
        path = ROOT / source
        require(path.is_file(), f"missing source: {source}")
        require("dynamic_point_set_rectangle_affine_rectangle_sum" in path.read_text(encoding="utf-8"),
                f"missing exported name in {source}")
    require((PACKAGE / "README.md").is_file(), "missing README")
    require((PACKAGE / "RIGHTS.md").is_file(), "missing rights note")
    require((ROOT / "benchmarks/dynamic_point_set_rectangle_affine_rectangle_sum_oracle.py").is_file(),
            "missing oracle")


if __name__ == "__main__":
    validate()
