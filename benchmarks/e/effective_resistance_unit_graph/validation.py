"""Unexecuted package and workload checks for effective resistance."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    spec = workload.get("input", {})
    if (workload.get("schema_version") != 1 or workload.get("id") != "effective-resistance-unit-graph-v1"
            or workload.get("algorithm") != "effective_resistance_unit_graph"
            or workload.get("function_symbol") != "effective_resistance_unit_graph"
            or spec != {"kind": "i64_array_scalar", "max_vertices": 6, "max_edges": 15, "invalid_result": -1}
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("effective resistance metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("effective resistance requires cases")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("invalid effective resistance case")
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(name, str) or not name or name in seen or not isinstance(values, list)
                or len(values) > 35 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 35
                or (null and values) or (not null and length != len(values))):
            raise ValueError("invalid effective resistance framing")
        seen.add(name)
        if type(case.get("expected_result")) is not int or case["expected_result"] != expected(None if null else values):
            raise ValueError(f"effective resistance reference mismatch: {name}")
    required = {"single_edge", "series", "triangle", "maximum_complete", "long_path",
                "disconnected", "duplicate_reverse", "self_loop", "truncated", "same_terminal", "null"}
    if not required <= seen:
        raise ValueError("effective resistance workload is missing required boundary cases")
    root = Path(__file__).resolve().parents[3]
    package = Path(__file__).resolve().parent
    for filename in ("README.md", "RIGHTS.md", "independent_oracle.py"):
        if not (package / filename).is_file():
            raise ValueError(f"effective resistance package missing {filename}")
    for language, ext in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                          ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                          ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "e" / f"effective_resistance_unit_graph.{ext}"
        if not source.is_file() or "effective_resistance_unit_graph" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"effective resistance source missing for {language}")
