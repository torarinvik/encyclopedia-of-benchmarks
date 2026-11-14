"""Static package and fixture validation for the batched subsequence draft."""
from pathlib import Path
from .primary_oracle import expected as primary
from .independent_oracle import expected as independent


def validate_workload(workload):
    spec = workload.get("input", {})
    if (workload.get("schema_version") != 1 or workload.get("id") != "subsequence-automaton-v1"
            or workload.get("algorithm") != "subsequence_automaton"
            or workload.get("function_symbol") != "subsequence_automaton"
            or spec.get("kind") != "i64_array_scalar"
            or spec.get("maximum_text_length") != 64 or spec.get("maximum_queries") != 32
            or spec.get("maximum_query_symbols") != 256 or spec.get("alphabet_size") != 4
            or spec.get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("subsequence automaton metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("subsequence automaton requires fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("invalid subsequence automaton fixture")
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(name, str) or not name or name in seen or not isinstance(values, list)
                or len(values) > 355 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values) or (not null and length != len(values))):
            raise ValueError("invalid subsequence automaton fixture framing")
        seen.add(name)
        data = None if null else values
        if (type(case.get("expected_result")) is not int or primary(data) != case["expected_result"]
                or independent(data) != case["expected_result"]):
            raise ValueError(f"subsequence automaton fixture mismatch: {name}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "s" / f"subsequence_automaton.{extension}"
        if not source.is_file() or "subsequence_automaton" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"subsequence automaton source missing for {language}")
