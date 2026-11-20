"""Static fixture/source validation for the bounded hanging-line profile."""

from pathlib import Path

from .independent_oracle import INVALID, expected
from .primary_oracle import MAX_PARSEABLE_INPUT_LENGTH, expected_result


def validate_workload(workload):
    spec = workload.get("input", {})
    if (
        workload.get("schema_version") != 1
        or workload.get("id") != "hanging-line-largest-rectangle-i64-array-scalar-v1"
        or workload.get("algorithm") != "hanging_line_largest_rectangle"
        or workload.get("function_symbol") != "hanging_line_largest_rectangle"
        or workload.get("abi") != "i64_array_scalar"
        or spec.get("kind") != "array_of_signed_64_bit_histogram_heights"
        or spec.get("length_range") != [0, 64]
        or spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or spec.get("element_range") != [0, 1_000_000]
        or spec.get("maximum_area") != 64_000_000
        or spec.get("invalid_result") != INVALID
        or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
    ):
        raise ValueError("hanging-line histogram metadata differs from its contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("hanging-line histogram requires fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("invalid hanging-line histogram case")
        name = case.get("id")
        values = case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (
            not isinstance(name, str)
            or not name
            or name in seen
            or not isinstance(values, list)
            or len(values) > 65
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
            or type(null) is not bool
            or type(length) is not int
            or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
            or (null and values)
            or (not null and length != len(values))
            or type(case.get("expected_result")) is not int
            or expected(None if null else values, length, null) != case["expected_result"]
            or expected_result(values, null, length) != case["expected_result"]
        ):
            raise ValueError(f"invalid or inconsistent hanging-line fixture: {name}")
        seen.add(name)

    root = Path(__file__).resolve().parents[3]
    source_paths = (
        root / "c/h/hanging_line_largest_rectangle.c",
        root / "c3/h/hanging_line_largest_rectangle.c3",
        root / "cpp/h/hanging_line_largest_rectangle.cpp",
        root / "elisa/h/hanging_line_largest_rectangle.elisa",
        root / "mojo/h/hanging_line_largest_rectangle.mojo",
        root / "nim/h/hanging_line_largest_rectangle.nim",
        root / "odin/h/hanging_line_largest_rectangle.odin",
        root / "rust/h/hanging_line_largest_rectangle.rs",
        root / "v/h/hanging_line_largest_rectangle.v",
        root / "zig/h/hanging_line_largest_rectangle.zig",
    )
    for path in source_paths:
        if not path.is_file() or "hanging_line_largest_rectangle" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"hanging-line source missing: {path.name}")
