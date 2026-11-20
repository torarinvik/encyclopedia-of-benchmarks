"""Static fixture and source validation for the bounded RSK profile."""

from pathlib import Path

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    INVALID,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected,
)


def validate_workload(workload):
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (
        workload.get("schema_version") != 1
        or workload.get("id") != "rsk-row-insertion-i64-array-scalar-v1"
        or workload.get("algorithm") != "rsk_row_insertion"
        or workload.get("function_symbol") != "rsk_row_insertion"
        or workload.get("abi") != "i64_array_scalar"
        or input_spec.get("kind") != "count_prefixed_zero_based_permutation"
        or input_spec.get("n_range") != [0, MAX_N]
        or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
        or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
        or input_spec.get("invalid_result") != INVALID
        or input_spec.get("null_input_result") != "invalid_result"
        or output_spec.get("kind") != "injective_base9_encoding_of_P_Q_row_assignments"
        or output_spec.get("maximum_encoding_bound") != 9 ** 17 - 1
        or output_spec.get("signed_i64") is not True
        or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
    ):
        raise ValueError("RSK workload metadata differs from its bounded contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("RSK workload requires fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("invalid RSK fixture")
        case_id = case.get("id")
        values = case.get("input_values")
        input_length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (
            not isinstance(case_id, str)
            or not case_id
            or case_id in seen
            or not isinstance(values, list)
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or type(is_null) is not bool
            or (is_null and values)
            or (not is_null and input_length != len(values))
            or type(case.get("expected_result")) is not int
        ):
            raise ValueError(f"invalid RSK fixture framing: {case_id}")
        primary = primary_expected(values, is_null, input_length)
        independent = independent_expected(values, is_null, input_length)
        if case["expected_result"] != primary or primary != independent:
            raise ValueError(f"RSK fixture differs between forward and inverse references: {case_id}")
        seen.add(case_id)

    root = Path(__file__).resolve().parents[3]
    source_paths = (
        root / "c/r/rsk_row_insertion.c",
        root / "c3/r/rsk_row_insertion.c3",
        root / "cpp/r/rsk_row_insertion.cpp",
        root / "elisa/r/rsk_row_insertion.elisa",
        root / "mojo/r/rsk_row_insertion.mojo",
        root / "nim/r/rsk_row_insertion.nim",
        root / "odin/r/rsk_row_insertion.odin",
        root / "rust/r/rsk_row_insertion.rs",
        root / "v/r/rsk_row_insertion.v",
        root / "zig/r/rsk_row_insertion.zig",
    )
    for path in source_paths:
        if not path.is_file() or "rsk_row_insertion" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"RSK source missing: {path.name}")
