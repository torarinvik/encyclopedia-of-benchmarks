"""Static metadata and fixture checks for difference_product."""
from pathlib import Path
from .independent_oracle import expected


def validate_workload(workload):
    if (workload.get("schema_version") != 1
            or workload.get("id") != "difference-product-v1"
            or workload.get("algorithm") != "difference_product"
            or workload.get("function_symbol") != "difference_product"
            or workload.get("input", {}).get("kind") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_count") != 65536
            or workload.get("input", {}).get("modulus") != 998244353
            or workload.get("input", {}).get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("difference_product metadata differs from its bounded contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("difference_product requires fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("difference_product fixture must be an object")
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            raise ValueError("difference_product fixture ids must be unique nonempty strings")
        seen.add(case_id)
        values = case.get("input_values")
        if (not isinstance(values, list) or len(values) > 65538
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
            raise ValueError("difference_product has invalid fixture values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values))
        if (type(null) is not bool or type(length) is not int or length < 0
                or (not null and length != len(values))):
            raise ValueError("difference_product has invalid fixture framing")
        if (type(case.get("expected_result")) is not int
                or case["expected_result"] != expected(None if null else values, length)):
            raise ValueError(f"difference_product fixture differs from direct oracle: {case.get('id')}")
    root = Path(__file__).resolve().parents[3]
    for language, ext in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"),
                          ("elisa", "elisa"), ("mojo", "mojo"), ("nim", "nim"),
                          ("odin", "odin"), ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        path = root / language / "d" / f"difference_product.{ext}"
        if not path.is_file() or "difference_product" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"difference_product source missing for {language}")
