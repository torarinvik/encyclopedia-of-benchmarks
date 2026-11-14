"""Validate the bounded resultant metadata and small independent fixtures."""
from pathlib import Path
from .remainder_oracle import expected as remainder_expected, parse
from .sylvester_oracle import expected as determinant_expected


def validate_workload(workload):
    if (workload.get("schema_version") != 1 or workload.get("id") != "polynomial-resultant-half-gcd-v1"
            or workload.get("algorithm") != "polynomial_resultant_half_gcd"
            or workload.get("function_symbol") != "polynomial_resultant_half_gcd"
            or workload.get("input", {}).get("kind") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_degree") != 50000
            or workload.get("input", {}).get("maximum_degree_sum") != 99998
            or workload.get("input", {}).get("modulus") != 998244353
            or workload.get("input", {}).get("invalid_result") != -1
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        raise ValueError("resultant workload metadata differs from its contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("resultant workload needs fixtures")
    names = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("resultant fixture must be an object")
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        if (not isinstance(name, str) or not name or name in names or not isinstance(values, list)
                or len(values) > 100002 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
                or type(null) is not bool or type(length) is not int or not 0 <= length <= 100002
                or (null and values) or (not null and length != len(values))):
            raise ValueError("invalid resultant fixture framing")
        names.add(name)
        data = None if null else values
        direct = remainder_expected(data)
        parsed = parse(data)
        if parsed is None or len(parsed[0]) + len(parsed[1]) - 2 <= 32:
            determinant = determinant_expected(data)
            if direct != determinant:
                raise ValueError(f"resultant references disagree: {name}")
        if type(case.get("expected_result")) is not int or case["expected_result"] != direct:
            raise ValueError(f"resultant fixture differs from references: {name}")
    root = Path(__file__).resolve().parents[3]
    for language, extension in (("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
                                ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
                                ("rust", "rs"), ("v", "v"), ("zig", "zig")):
        source = root / language / "p" / f"polynomial_resultant_half_gcd.{extension}"
        if not source.is_file() or "polynomial_resultant_half_gcd" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"resultant source missing for {language}")
    for name in ("polynomial_resultant_half_gcd_primitives.hpp",
                 "polynomial_resultant_half_gcd_reduction.hpp",
                 "polynomial_resultant_half_gcd_kernel.hpp"):
        if not (root / "cpp" / "p" / name).is_file():
            raise ValueError(f"resultant C++ dependency missing: {name}")
