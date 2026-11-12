"""Static workload, dual-oracle, rights-note, and port-path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))

from q_binomial_coefficient_prime_mod_oracle import expected_output  # noqa: E402
from q_binomial_coefficient_prime_mod_independent_oracle import (  # noqa: E402
    expected_output as independent_output,
)

SOURCE_URL = (
    "https://github.com/yosupo06/library-checker-problems/blob/master/"
    "enumerative_combinatorics/q_binomial_coefficient_prime_mod/task.md"
)
PORTS = (
    "c/q/q_binomial_coefficient_prime_mod.c",
    "c3/q/q_binomial_coefficient_prime_mod.c3",
    "cpp/q/q_binomial_coefficient_prime_mod.cpp",
    "elisa/q/q_binomial_coefficient_prime_mod.elisa",
    "mojo/q/q_binomial_coefficient_prime_mod.mojo",
    "nim/q/q_binomial_coefficient_prime_mod.nim",
    "odin/q/q_binomial_coefficient_prime_mod.odin",
    "rust/q/q_binomial_coefficient_prime_mod.rs",
    "v/q/q_binomial_coefficient_prime_mod.v",
    "zig/q/q_binomial_coefficient_prime_mod.zig",
)


def verify_workload():
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "q_binomial_coefficient_prime_mod"
            or workload.get("function_symbol") != "q_binomial_coefficient_prime_mod"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != 35
            or workload.get("input", {}).get("maximum_parseable_input_length") != 36
            or workload.get("output", {}).get("kind") != "byte_array"
            or workload.get("output", {}).get("maximum_bytes") != 16
            or workload.get("workspace", {}).get("bytes") != 2312
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_bytes_output_call"
            or workload.get("contract", {}).get("recurrence")
            != "G(n,k)=G(n-1,k)+q^(n-k)G(n-1,k-1) modulo m, with G(n,0)=G(n,n)=1"):
        raise ValueError("workload identity, bounds, or source attribution differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        if case.get("input_length") != len(values) and not case.get("input_is_null", False):
            raise ValueError(f"input length differs from values: {case['id']}")
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = expected_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        if primary != (case.get("expected_result"), expected_bytes):
            raise ValueError(f"fixture differs from recurrence oracle: {case['id']}")
        if independent != primary:
            raise ValueError(f"subset oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        raise ValueError("README or rights note omits the official task")
    if "clean-room" not in rights or "No upstream implementation" not in rights:
        raise ValueError("rights note does not establish independent implementation")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "q_binomial_coefficient_prime_mod" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
