#!/usr/bin/env python3
"""Statically check the bounded static rectangle-sum package."""

from __future__ import annotations

import json
from pathlib import Path

from static_rectangle_add_rectangle_sum_oracle import (
    MAX_N, MAX_Q, MAX_COORD, MOD, MAX_VALID_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES,
)
from static_rectangle_add_rectangle_sum_verifier_oracle import expected_output

ROOT = Path(__file__).resolve().parents[1]
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_rectangle_add_rectangle_sum/task.md"
SOURCE_PATHS = (
    "c/s/static_rectangle_add_rectangle_sum.c",
    "c3/s/static_rectangle_add_rectangle_sum.c3",
    "cpp/s/static_rectangle_add_rectangle_sum.cpp",
    "elisa/s/static_rectangle_add_rectangle_sum.elisa",
    "mojo/s/static_rectangle_add_rectangle_sum.mojo",
    "nim/s/static_rectangle_add_rectangle_sum.nim",
    "odin/s/static_rectangle_add_rectangle_sum.odin",
    "rust/s/static_rectangle_add_rectangle_sum.rs",
    "v/s/static_rectangle_add_rectangle_sum.v",
    "zig/s/static_rectangle_add_rectangle_sum.zig",
)


def validate_workload(workload: object) -> None:
    if not isinstance(workload, dict):
        raise ValueError("workload root must be an object")
    if (set(workload) != {
            "schema_version", "id", "algorithm", "function_symbol", "abi",
            "description", "source", "input", "contract", "output",
            "workspace", "measurement", "cases"}
            or workload.get("schema_version") != 1
            or workload.get("id") != "library-checker-static-rectangle-add-rectangle-sum-compressed-cells-v1"
            or workload.get("algorithm") != "static_rectangle_add_rectangle_sum"
            or workload.get("function_symbol") != "static_rectangle_add_rectangle_sum"
            or workload.get("abi") != "i64_array_bytes_output"
            or TASK_URL not in str(workload.get("source"))):
        raise ValueError("static rectangle workload identity or provenance differs from its contract")

    input_spec = workload["input"]
    if (input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[N,Q,(left,down,right,up,weight)*N,(left,down,right,up)*Q]"
            or input_spec.get("update_count_range") != [1, MAX_N]
            or input_spec.get("query_count_range") != [0, MAX_Q]
            or input_spec.get("coordinate_range") != [0, MAX_COORD]
            or input_spec.get("weight_range") != [0, MOD - 1]
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or input_spec.get("null_input_result") != -1):
        raise ValueError("static rectangle input contract mismatch")

    contract = workload["contract"]
    if (contract.get("modulus") != MOD
            or contract.get("maximum_boundaries_per_axis") != 128
            or "Apply all N rectangle additions" not in contract.get("operation", "")
            or contract.get("invalid_input_result") != -1
            or contract.get("output_error_result") != -2
            or contract.get("no_write_on_error") is not True):
        raise ValueError("static rectangle operation contract mismatch")

    output_spec = workload["output"]
    if (output_spec.get("kind") != "little_endian_signed_64_bit_array"
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_spec.get("element_width_bytes") != 8
            or output_spec.get("maximum_elements") != MAX_Q
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -2
            or output_spec.get("no_write_on_error") is not True
            or workload.get("workspace") != {
                "bytes": MAX_WORKSPACE_BYTES,
                "meaning": "Fixed coordinate arrays, two-dimensional corner-difference grid, area-weighted modular prefix grid, staged query answers, and temporary sort storage.",
            }):
        raise ValueError("static rectangle output or workspace contract mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("static rectangle workload must include fixtures")
    seen_ids: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict)
                or not {"id", "input_values", "input_length", "output_capacity",
                        "expected_result", "expected_output_hex"}.issubset(case)
                or set(case) - {"id", "input_values", "input_length", "output_capacity",
                                "output_is_null", "input_is_null", "expected_result",
                                "expected_output_hex"}):
            raise ValueError("static rectangle fixture fields differ from its contract")
        case_id = case["id"]
        values = case["input_values"]
        length = case["input_length"]
        capacity = case["output_capacity"]
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(case_id, str) or case_id in seen_ids
                or not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int or length != len(values)
                or length > MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool or type(input_is_null) is not bool
                or (input_is_null and values)):
            raise ValueError(f"static rectangle fixture framing is invalid: {case_id}")
        seen_ids.add(case_id)
        result, payload = expected_output(
            values, capacity, output_is_null, input_is_null, length)
        if (type(case.get("expected_result")) is not int
                or case["expected_result"] != result
                or case.get("expected_output_hex") != payload.hex()):
            raise ValueError(f"static rectangle fixture differs from the compressed-cell oracle: {case_id}")


def validate_sources() -> None:
    readme = ROOT / "benchmarks/s/static_rectangle_add_rectangle_sum/README.md"
    contents = readme.read_text(encoding="utf-8")
    if TASK_URL not in contents or "independent verifier scans" not in contents:
        raise ValueError("static rectangle README is missing provenance or oracle notes")
    for relative in SOURCE_PATHS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"missing source file {relative}")
        if relative not in contents:
            raise ValueError(f"README is missing the source link: {relative}")
        if "static_rectangle_add_rectangle_sum" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"source is missing the exported symbol: {relative}")


def main() -> int:
    package = ROOT / "benchmarks/s/static_rectangle_add_rectangle_sum"
    workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    return 0


if __name__ == "__main__":
    main()
