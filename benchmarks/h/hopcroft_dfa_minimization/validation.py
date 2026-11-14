"""Metadata and fixture checks for the DFA-minimization draft."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    if (workload.get("schema_version") != 1 or workload.get("id") != "hopcroft-dfa-minimization-v1"
            or workload.get("algorithm") != "hopcroft_dfa_minimization"
            or workload.get("function_symbol") != "hopcroft_dfa_minimization"
            or workload.get("input", {}).get("kind") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_states") != 4096
            or workload.get("input", {}).get("maximum_alphabet") != 4
            or workload.get("input", {}).get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("DFA-minimization metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("DFA-minimization workload needs cases")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("DFA-minimization fixture must be an object")
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(name, str) or not name or name in seen or not isinstance(values, list)
                or len(values) > 20483 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values) or (not null and length != len(values))):
            raise ValueError("invalid DFA-minimization fixture framing")
        seen.add(name)
        if type(case.get("expected_result")) is not int or case["expected_result"] != expected(None if null else values):
            raise ValueError(f"DFA-minimization fixture mismatch: {name}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "h" / f"hopcroft_dfa_minimization.{extension}"
        if not source.is_file() or "hopcroft_dfa_minimization" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"DFA-minimization source missing for {language}")
