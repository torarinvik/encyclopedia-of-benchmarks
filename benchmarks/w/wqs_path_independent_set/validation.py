"""Unexecuted fixture and source-inventory checks for the WQS draft."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    spec = workload.get("input", {})
    if (workload.get("schema_version") != 1 or workload.get("id") != "wqs-path-independent-set-v1"
            or workload.get("algorithm") != "wqs_path_independent_set"
            or workload.get("function_symbol") != "wqs_path_independent_set"
            or spec.get("kind") != "i64_array_scalar" or spec.get("maximum_n") != 128
            or spec.get("maximum_absolute_weight") != 1000 or spec.get("invalid_result") != -1000000000
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("WQS path metadata differs from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("WQS path workload requires cases")
    names = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("invalid WQS path case")
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(name, str) or not name or name in names or not isinstance(values, list)
                or len(values) > 131 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values) or (not null and length != len(values))):
            raise ValueError("invalid WQS path fixture framing")
        names.add(name)
        if type(case.get("expected_result")) is not int or expected(None if null else values) != case["expected_result"]:
            raise ValueError(f"WQS path fixture mismatch: {name}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "w" / f"wqs_path_independent_set.{extension}"
        if not source.is_file() or "wqs_path_independent_set" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"WQS path source missing for {language}")
