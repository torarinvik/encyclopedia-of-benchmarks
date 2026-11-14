"""Metadata and fixture validation for the hook-length scalar workload."""
from pathlib import Path

from .independent_oracle import expected
from .small_shape_oracle import count_tableaux


def validate_workload(workload):
    if (workload.get("schema_version") != 1
            or workload.get("id") != "hook-length-tableaux-v1"
            or workload.get("algorithm") != "hook_length_tableaux"
            or workload.get("function_symbol") != "hook_length_tableaux"
            or workload.get("input", {}).get("maximum_rows") != 65536
            or workload.get("input", {}).get("maximum_cells") != 1000000
            or workload.get("input", {}).get("modulus") != 998244353
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("hook_length_tableaux workload metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("hook_length_tableaux requires fixtures")
    for case in cases:
        values = case.get("input_values")
        if (not isinstance(values, list) or len(values) > 65538
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
            raise ValueError("hook_length_tableaux has malformed fixture values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values))
        if type(null) is not bool or type(length) is not int or (not null and length != len(values)):
            raise ValueError("hook_length_tableaux has malformed fixture framing")
        if case.get("expected_result") != expected(None if null else values, length):
            raise ValueError(f"hook_length_tableaux fixture differs from its oracle: {case.get('id')}")
        if not null and values and expected(values) >= 0 and sum(values[1:]) <= 16:
            if case["expected_result"] != count_tableaux(tuple(values[1:])):
                raise ValueError(f"hook_length_tableaux fixture differs from corner-removal count: {case.get('id')}")
    root = Path(__file__).resolve().parents[3]
    for language, ext in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"),
                          ("elisa", "elisa"), ("mojo", "mojo"), ("nim", "nim"),
                          ("odin", "odin"), ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        path = root / language / "h" / f"hook_length_tableaux.{ext}"
        if not path.is_file() or "hook_length_tableaux" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"hook_length_tableaux source missing for {language}")
