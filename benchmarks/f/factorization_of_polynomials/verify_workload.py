"""Static workload, oracle, provenance, and ten-port inventory checker."""

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
SYMBOL = "factorization_of_polynomials"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/factorization_of_polynomials/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/factorization_of_polynomials/info.toml"
PORTS = {
    "c": ROOT / "c/f/factorization_of_polynomials.c",
    "c3": ROOT / "c3/f/factorization_of_polynomials.c3",
    "cpp": ROOT / "cpp/f/factorization_of_polynomials.cpp",
    "elisa": ROOT / "elisa/f/factorization_of_polynomials.elisa",
    "mojo": ROOT / "mojo/f/factorization_of_polynomials.mojo",
    "nim": ROOT / "nim/f/factorization_of_polynomials.nim",
    "odin": ROOT / "odin/f/factorization_of_polynomials.odin",
    "rust": ROOT / "rust/f/factorization_of_polynomials.rs",
    "v": ROOT / "v/f/factorization_of_polynomials.v",
    "zig": ROOT / "zig/f/factorization_of_polynomials.zig",
}
REQUIRED_CASES = {
    "unit-polynomial-no-factors", "single-linear-factor", "repeated-linear-factor",
    "distinct-linear-and-quadratic-factors", "irreducible-quartic",
    "irreducible-quadratic-over-f3", "repeated-linear-over-f3", "non-monic-input",
    "unsupported-prime-profile", "coefficient-out-of-range", "degree-above-profile",
    "truncated-input", "extra-input-word", "short-output-capacity",
    "null-output-buffer", "null-input-pointer",
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
            or source.get("task_url") != TASK_URL or source.get("limits_url") != LIMITS_URL
            or source.get("repository_license") != "Apache-2.0"):
        errors.append("workload identity or official source attribution mismatch")
    if (workload.get("oracle") != "benchmarks/f/factorization_of_polynomials/primary_oracle.py"
            or workload.get("independent_oracle") != "benchmarks/f/factorization_of_polynomials/independent_oracle.py"):
        errors.append("oracle paths mismatch")
    contract = workload.get("contract", {})
    if (contract.get("n_range") != [0, 8] or contract.get("prime_values") != [2, 3, 5]
            or contract.get("leading_coefficient") != 1):
        errors.append("bounded finite-field factorization contract mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 11
            or workload.get("input", {}).get("maximum_parseable_length") != 12
            or workload.get("output", {}).get("maximum_bytes") != 216
            or workload.get("output", {}).get("maximum_output_elements") != 27
            or workload.get("workspace", {}).get("bytes") != 2048):
        errors.append("input, output, or workspace bounds mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixtures"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases) or not REQUIRED_CASES <= identifiers:
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
        errors.append("documentation omits task attribution or rights")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
