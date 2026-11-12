"""Static workload, oracle, rights, and ten-port package inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "product_of_polynomial_sequence"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/product_of_polynomial_sequence/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/product_of_polynomial_sequence/info.toml"
PORTS = {
    "c": ROOT / "c/p/product_of_polynomial_sequence.c",
    "c3": ROOT / "c3/p/product_of_polynomial_sequence.c3",
    "cpp": ROOT / "cpp/p/product_of_polynomial_sequence.cpp",
    "elisa": ROOT / "elisa/p/product_of_polynomial_sequence.elisa",
    "mojo": ROOT / "mojo/p/product_of_polynomial_sequence.mojo",
    "nim": ROOT / "nim/p/product_of_polynomial_sequence.nim",
    "odin": ROOT / "odin/p/product_of_polynomial_sequence.odin",
    "rust": ROOT / "rust/p/product_of_polynomial_sequence.rs",
    "v": ROOT / "v/p/product_of_polynomial_sequence.v",
    "zig": ROOT / "zig/p/product_of_polynomial_sequence.zig",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL or source.get("limits_url") != LIMITS_URL
            or source.get("official_n_max") != 500000 or source.get("official_degree_sum_max") != 500000
            or source.get("modulus") != 998244353 or source.get("repository_license") != "Apache-2.0"):
        errors.append("workload identity or official source attribution mismatch")
    contract = workload.get("contract", {})
    if (contract.get("factor_count_range") != [0, 6]
            or contract.get("degree_per_factor_range") != [0, 4]
            or contract.get("total_degree_max") != 24
            or contract.get("coefficient_range") != [0, 998244352]
            or contract.get("modulus") != 998244353):
        errors.append("bounded product-of-polynomials contract mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 37
            or workload.get("input", {}).get("maximum_parseable_length") != 38
            or workload.get("output", {}).get("maximum_output_elements") != 25
            or workload.get("output", {}).get("maximum_bytes") != 200
            or workload.get("workspace", {}).get("maximum_bytes") != 1536):
        errors.append("input, output, or workspace bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixtures"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases):
        errors.append("fixture IDs are missing or duplicated")
    for case in cases:
        if not isinstance(case, dict):
            errors.append("fixture entry is not an object")
            continue
        values = case.get("input_values", [])
        input_length = case.get("input_length")
        primary = primary_output(values, case.get("output_capacity"),
                                 case.get("output_is_null", False),
                                 case.get("input_is_null", False), input_length)
        independent = independent_output(values, case.get("output_capacity"),
                                         case.get("output_is_null", False),
                                         case.get("input_is_null", False), input_length)
        if (input_length != len(values) or primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or LIMITS_URL not in readme or "Apache-2.0" not in rights:
        errors.append("documentation omits source attribution or rights")
    if ("balanced product tree" not in readme or "sequential" not in readme
            or "empty product" not in readme):
        errors.append("README omits algorithm or local contract distinctions")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors


if __name__ == "__main__":
    print("checked static polynomial-product package")
