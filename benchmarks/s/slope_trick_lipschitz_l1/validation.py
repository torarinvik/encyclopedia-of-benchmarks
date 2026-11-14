"""Static metadata, source inventory, and reference fixture checks."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    spec = workload.get("input", {})
    if (workload.get("schema_version") != 1 or workload.get("id") != "slope-trick-lipschitz-l1-v1"
            or workload.get("algorithm") != "slope_trick_lipschitz_l1"
            or workload.get("function_symbol") != "slope_trick_lipschitz_l1"
            or spec.get("kind") != "i64_array_scalar" or spec.get("maximum_n") != 128
            or spec.get("maximum_h") != 100 or spec.get("maximum_value") != 100
            or spec.get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("slope-trick metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("slope-trick workload requires cases")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("invalid slope-trick case")
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(name, str) or not name or name in seen or not isinstance(values, list)
                or len(values) > 131 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values) or (not null and length != len(values))):
            raise ValueError("invalid slope-trick case framing")
        seen.add(name)
        if type(case.get("expected_result")) is not int or expected(None if null else values) != case["expected_result"]:
            raise ValueError(f"slope-trick fixture mismatch: {name}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "s" / f"slope_trick_lipschitz_l1.{extension}"
        if not source.is_file() or "slope_trick_lipschitz_l1" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"slope-trick source missing for {language}")
