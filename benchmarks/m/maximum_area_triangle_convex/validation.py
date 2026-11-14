"""Static package and workload checks for the maximum-triangle draft."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    if (workload.get("schema_version") != 1
            or workload.get("id") != "maximum-area-triangle-convex-v1"
            or workload.get("algorithm") != "maximum_area_triangle_convex"
            or workload.get("function_symbol") != "maximum_area_triangle_convex"
            or workload.get("input", {}).get("kind") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_vertices") != 1024
            or workload.get("input", {}).get("coordinate_limit") != 1000000
            or workload.get("input", {}).get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("maximum-area triangle metadata differs from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("maximum-area triangle requires fixtures")
    ids = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("fixture must be an object")
        identifier = case.get("id")
        values = case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(identifier, str) or not identifier or identifier in ids
                or not isinstance(values, list) or len(values) > 2050
                or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values)
                or (not null and length != len(values))):
            raise ValueError("invalid maximum-area triangle fixture")
        ids.add(identifier)
        if type(case.get("expected_result")) is not int or case["expected_result"] != expected(None if null else values):
            raise ValueError(f"maximum-area triangle fixture mismatch: {identifier}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "m" / f"maximum_area_triangle_convex.{extension}"
        if not source.is_file() or "maximum_area_triangle_convex" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"maximum-area triangle source missing for {language}")
