"""Static workload and source-presence checks for range_affine_range_sum."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

from range_affine_range_sum_oracle import (
    MAX_PARSEABLE_INPUT_VALUES,
    MAX_VALID_INPUT_VALUES,
    expected_result,
)

ROOT = Path(__file__).resolve().parents[1]
WORKLOAD_PATH = ROOT / "benchmarks" / "r" / "range_affine_range_sum" / "workload.json"
SYMBOL = "range_affine_range_sum_benchmark"
SOURCE_FILES = (
    "c/r/range_affine_range_sum.c",
    "c3/r/range_affine_range_sum.c3",
    "cpp/r/range_affine_range_sum.cpp",
    "elisa/r/range_affine_range_sum.elisa",
    "mojo/r/range_affine_range_sum.mojo",
    "nim/r/range_affine_range_sum.nim",
    "odin/r/range_affine_range_sum.odin",
    "rust/r/range_affine_range_sum.rs",
    "v/r/range_affine_range_sum.v",
    "zig/r/range_affine_range_sum.zig",
)
EXPECTED_CASE_IDS = {
    "overlapping_affine_updates_and_queries",
    "modular_wrap_and_composition_order",
    "single_element_modular_composition",
    "truncated_query_record",
}


def verify_workload(workload: Mapping[str, object]) -> None:
    """Check bounded metadata and fixtures against the direct-array oracle."""
    if (
        workload.get("schema_version") != 1
        or workload.get("id") != "library-checker-range-affine-range-sum-bounded-i64-array-scalar-v1"
        or workload.get("algorithm") != "range_affine_range_sum"
        or workload.get("function_symbol") != SYMBOL
    ):
        raise ValueError("workload identity differs from the bounded profile")

    input_spec = workload.get("input")
    if not isinstance(input_spec, Mapping):
        raise ValueError("workload input metadata must be an object")
    if (
        input_spec.get("n_range") != [1, 64]
        or input_spec.get("q_range") != [1, 64]
        or input_spec.get("initial_value_and_offset_range") != [0, 998244352]
        or input_spec.get("multiplier_range") != [1, 998244352]
        or input_spec.get("modulus") != 998244353
        or input_spec.get("maximum_valid_input_values") != MAX_VALID_INPUT_VALUES
        or input_spec.get("maximum_parseable_input_values") != MAX_PARSEABLE_INPUT_VALUES
    ):
        raise ValueError("workload input bounds differ from the bounded profile")

    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases if isinstance(case, Mapping)} != EXPECTED_CASE_IDS:
        raise ValueError("workload fixture set differs from the package cases")
    if len(cases) != len(EXPECTED_CASE_IDS):
        raise ValueError("workload contains duplicate or malformed fixture entries")

    for case in cases:
        if not isinstance(case, Mapping):
            raise ValueError("each workload fixture must be an object")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"{case.get('id')}: malformed input_values/input_length")
        if len(values) > MAX_PARSEABLE_INPUT_VALUES:
            raise ValueError(f"{case.get('id')}: input exceeds the parseable bound")
        result = expected_result(values)
        if result != case.get("expected_result"):
            raise AssertionError(
                f"{case.get('id')}: oracle returned {result}, expected {case.get('expected_result')}"
            )
        if result != -1 and len(values) > MAX_VALID_INPUT_VALUES:
            raise ValueError(f"{case.get('id')}: valid input exceeds the valid bound")


def verify_static_sources() -> None:
    """Check that each port, README, and rights note exists and names the ABI symbol."""
    for relative_path in SOURCE_FILES:
        path = ROOT / relative_path
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            raise ValueError(f"missing source port {relative_path}") from error
        if SYMBOL not in source:
            raise ValueError(f"{relative_path} does not export {SYMBOL}")
    package = ROOT / "benchmarks" / "r" / "range_affine_range_sum"
    for filename in ("README.md", "RIGHTS.md", "workload.json"):
        if not (package / filename).is_file():
            raise ValueError(f"missing package file {filename}")


def verify_package() -> None:
    """Read and statically inspect the workload and package source files."""
    try:
        workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read workload JSON: {error}") from error
    if not isinstance(workload, Mapping):
        raise ValueError("workload JSON must contain an object")
    verify_workload(workload)
    verify_static_sources()
