"""Metadata and fixture checks for the minimal-concatenation draft."""
from pathlib import Path
from .independent_oracle import expected_output


def validate_workload(workload):
    metadata = workload.get("input", {})
    output = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("id") != "lexicographically-minimal-concatenation-v1"
            or workload.get("algorithm") != "lexicographically_minimal_concatenation"
            or workload.get("function_symbol") != "lexicographically_minimal_concatenation"
            or metadata.get("kind") != "signed_i64_array"
            or metadata.get("maximum_strings") != 16384
            or metadata.get("maximum_total_bytes") != 65536
            or metadata.get("maximum_valid_input_length") != 81921
            or metadata.get("maximum_parseable_input_length") != 81922
            or output.get("kind") != "byte_array"
            or output.get("maximum_output_bytes") != 65536
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        raise ValueError("minimal-concatenation workload metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("minimal-concatenation workload needs fixtures")
    ids = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("minimal-concatenation fixture must be an object")
        name, values = case.get("id"), case.get("input_values")
        if (not isinstance(name, str) or not name or name in ids or not isinstance(values, list)
                or len(values) > 81922 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
            raise ValueError("invalid minimal-concatenation fixture")
        ids.add(name)
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values))
        capacity = case.get("output_capacity", 65536)
        null_output = case.get("output_is_null", False)
        if (type(capacity) is not int or not 0 <= capacity <= 65536 or type(null_output) is not bool
                or type(input_is_null) is not bool or type(input_length) is not int
                or not 0 <= input_length <= 81922
                or (input_is_null and values) or (not input_is_null and input_length != len(values))):
            raise ValueError("invalid minimal-concatenation framing")
        result, data = expected_output(values, capacity, null_output, input_is_null, input_length)
        if (type(case.get("expected_result")) is not int or case["expected_result"] != result
                or case.get("expected_output_hex") != data.hex()):
            raise ValueError(f"minimal-concatenation fixture mismatch: {name}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "l" / f"lexicographically_minimal_concatenation.{extension}"
        if not source.is_file() or "lexicographically_minimal_concatenation" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"minimal-concatenation source missing for {language}")
