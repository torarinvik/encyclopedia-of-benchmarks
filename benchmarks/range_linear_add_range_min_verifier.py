"""Static source and workload checks for range_linear_add_range_min."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from range_linear_add_range_min_oracle import (
    MAX_PARSEABLE_INPUT_VALUES,
    MAX_VALID_INPUT_VALUES,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks" / "r" / "range_linear_add_range_min"
WORKLOAD_PATH = PACKAGE / "workload.json"
SYMBOL = "range_linear_add_range_min_benchmark"
SOURCE_FILES = (
    "c/r/range_linear_add_range_min.c",
    "c3/r/range_linear_add_range_min.c3",
    "cpp/r/range_linear_add_range_min.cpp",
    "elisa/r/range_linear_add_range_min.elisa",
    "mojo/r/range_linear_add_range_min.mojo",
    "nim/r/range_linear_add_range_min.nim",
    "odin/r/range_linear_add_range_min.odin",
    "rust/r/range_linear_add_range_min.rs",
    "v/r/range_linear_add_range_min.v",
    "zig/r/range_linear_add_range_min.zig",
)
EXPECTED_CASE_IDS = {
    "full_range_update_then_subrange_queries",
    "negative_slope_moves_minimum_to_right",
    "partial_update_crosses_block_boundary",
    "truncated_linear_update",
}


def verify_workload(workload: Mapping[str, object]) -> None:
    if (
        workload.get("schema_version") != 1
        or workload.get("id") != "library-checker-range-linear-add-range-min-bounded-i64-array-scalar-v1"
        or workload.get("algorithm") != "range_linear_add_range_min"
        or workload.get("function_symbol") != SYMBOL
    ):
        raise ValueError("workload identity differs from the bounded profile")
    input_spec = workload.get("input")
    if not isinstance(input_spec, Mapping) or (
        input_spec.get("n_range") != [1, 64]
        or input_spec.get("q_range") != [1, 64]
        or input_spec.get("initial_value_range") != [-1_000_000, 1_000_000]
        or input_spec.get("slope_range") != [-99, 99]
        or input_spec.get("intercept_range") != [-100_000, 100_000]
        or input_spec.get("maximum_valid_input_values") != MAX_VALID_INPUT_VALUES
        or input_spec.get("maximum_parseable_input_values") != MAX_PARSEABLE_INPUT_VALUES
    ):
        raise ValueError("workload input metadata differs from the bounded profile")
    cases = workload.get("cases")
    if not isinstance(cases, list) or {
        case.get("id") for case in cases if isinstance(case, Mapping)
    } != EXPECTED_CASE_IDS or len(cases) != len(EXPECTED_CASE_IDS):
        raise ValueError("workload fixture set differs from the package contract")
    for case in cases:
        if not isinstance(case, Mapping):
            raise ValueError("each workload fixture must be an object")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"{case.get('id')}: malformed input framing")
        if len(values) > MAX_PARSEABLE_INPUT_VALUES:
            raise ValueError(f"{case.get('id')}: input exceeds the parseable bound")
        result = expected_result(values)
        if result != case.get("expected_result"):
            raise ValueError(f"{case.get('id')}: expected result differs from the direct oracle")
        if result != -1 and len(values) > MAX_VALID_INPUT_VALUES:
            raise ValueError(f"{case.get('id')}: valid input exceeds the valid frame bound")


def verify_static_sources() -> None:
    for relative_path in SOURCE_FILES:
        path = ROOT / relative_path
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            raise ValueError(f"missing source port {relative_path}") from error
        if SYMBOL not in source:
            raise ValueError(f"{relative_path} does not export {SYMBOL}")
    for filename in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / filename).is_file():
            raise ValueError(f"missing package file {filename}")


def verify_package() -> None:
    try:
        workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read workload JSON: {error}") from error
    if not isinstance(workload, Mapping):
        raise ValueError("workload JSON must contain an object")
    verify_workload(workload)
    verify_static_sources()
