"""Workload validation for range-constraint topological feasibility."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    if (workload.get("schema_version") != 1
            or workload.get("id") != "range-constraint-topological-feasibility-v1"
            or workload.get("algorithm") != "range_constraint_topological_feasibility"
            or workload.get("function_symbol") != "range_constraint_topological_feasibility"
            or workload.get("input", {}).get("kind") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_vertices") != 4096
            or workload.get("input", {}).get("maximum_constraints") != 8192
            or workload.get("input", {}).get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("range-constraint workload metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("range-constraint workload requires cases")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("range-constraint fixture must be an object")
        identifier, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(identifier, str) or not identifier or identifier in seen
                or not isinstance(values, list) or len(values) > 32771
                or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values) or (not null and length != len(values))):
            raise ValueError("range-constraint fixture framing is invalid")
        seen.add(identifier)
        if type(case.get("expected_result")) is not int or case["expected_result"] != expected(None if null else values):
            raise ValueError(f"range-constraint fixture mismatch: {identifier}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "r" / f"range_constraint_topological_feasibility.{extension}"
        if not source.is_file() or "range_constraint_topological_feasibility" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"range-constraint source missing for {language}")
