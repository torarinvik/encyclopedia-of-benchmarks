"""Static workload, dual-oracle, rights, and ten-port package inventory."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "polynomial_root_finding"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/polynomial_root_finding/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/polynomial_root_finding/info.toml"
PORTS = {
    "c": ROOT / "c/p/polynomial_root_finding.c",
    "c3": ROOT / "c3/p/polynomial_root_finding.c3",
    "cpp": ROOT / "cpp/p/polynomial_root_finding.cpp",
    "elisa": ROOT / "elisa/p/polynomial_root_finding.elisa",
    "mojo": ROOT / "mojo/p/polynomial_root_finding.mojo",
    "nim": ROOT / "nim/p/polynomial_root_finding.nim",
    "odin": ROOT / "odin/p/polynomial_root_finding.odin",
    "rust": ROOT / "rust/p/polynomial_root_finding.rs",
    "v": ROOT / "v/p/polynomial_root_finding.v",
    "zig": ROOT / "zig/p/polynomial_root_finding.zig",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != LIMITS_URL
            or source.get("official_n_max") != 4000
            or source.get("modulus") != 998244353
            or source.get("repository_license") != "Apache-2.0"):
        errors.append("workload identity or official source attribution mismatch")
    contract = workload.get("contract", {})
    if (contract.get("n_range") != [0, 8]
            or contract.get("coefficient_range") != [0, 998244352]
            or contract.get("leading_coefficient_nonzero") is not True
            or contract.get("modulus") != 998244353
            or "gcd(f,x^p-x)" not in contract.get("algorithm", "")
            or "directly evaluate" not in contract.get("independent_algorithm", "")):
        errors.append("bounded polynomial root-finding contract mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 10
            or workload.get("input", {}).get("maximum_parseable_length") != 10
            or workload.get("output", {}).get("maximum_output_elements") != 9
            or workload.get("output", {}).get("maximum_bytes") != 72):
        errors.append("input or output bounds mismatch")
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
    if ("Cantor-Zassenhaus" not in readme or "quadratic-character" not in readme
            or "independent oracle" not in readme):
        errors.append("README omits the primary method or independent oracle")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors


if __name__ == "__main__":
    print("checked static polynomial root finding package")
