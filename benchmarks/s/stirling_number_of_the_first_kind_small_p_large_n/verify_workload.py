"""Static dual-oracle, metadata, rights, and ten-port package checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))

from stirling_number_of_the_first_kind_small_p_large_n_oracle import (  # noqa: E402
    MAX_K,
    MAX_N,
    MAX_T,
    MODULUS_MAX,
    MODULUS_MIN,
    expected_result,
)
from stirling_number_of_the_first_kind_small_p_large_n_verifier_oracle import (  # noqa: E402
    expected_result as independent_result,
)

SOURCE_URL = (
    "https://github.com/yosupo06/library-checker-problems/blob/master/"
    "enumerative_combinatorics/stirling_number_of_the_first_kind_small_p_large_n/task.md"
)
PORTS = (
    "c/s/stirling_number_of_the_first_kind_small_p_large_n.c",
    "c3/s/stirling_number_of_the_first_kind_small_p_large_n.c3",
    "cpp/s/stirling_number_of_the_first_kind_small_p_large_n.cpp",
    "elisa/s/stirling_number_of_the_first_kind_small_p_large_n.elisa",
    "mojo/s/stirling_number_of_the_first_kind_small_p_large_n.mojo",
    "nim/s/stirling_number_of_the_first_kind_small_p_large_n.nim",
    "odin/s/stirling_number_of_the_first_kind_small_p_large_n.odin",
    "rust/s/stirling_number_of_the_first_kind_small_p_large_n.rs",
    "v/s/stirling_number_of_the_first_kind_small_p_large_n.v",
    "zig/s/stirling_number_of_the_first_kind_small_p_large_n.zig",
)


def verify_workload():
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "stirling_number_of_the_first_kind_small_p_large_n"
            or workload.get("function_symbol") != "stirling_number_of_the_first_kind_small_p_large_n"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("T_range") != [1, MAX_T]
            or workload.get("input", {}).get("p_range") != [MODULUS_MIN, MODULUS_MAX]
            or workload.get("input", {}).get("n_range") != [0, MAX_N]
            or workload.get("input", {}).get("k_range") != [0, MAX_K]
            or workload.get("output", {}).get("formula") != "sum((i+1)^2*s(ni,ki)) mod p"
            or workload.get("contract", {}).get("official_n_range") != [0, MAX_N]
            or workload.get("contract", {}).get("coefficient_rule")
            != "p-1>k, so if q>k then s(n,k)=0; otherwise s(n,k)=(-1)^q times the degree-(k-q) coefficient of R_r"
            or MODULUS_MIN - 1 <= MAX_K):
        raise ValueError("workload identity, profile, or source attribution differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture input frame differs: {case['id']}")
        primary = expected_result(values)
        independent = independent_result(values)
        if primary != case.get("expected_result"):
            raise ValueError(f"fixture differs from residue-block oracle: {case['id']}")
        if independent != primary:
            raise ValueError(f"truncated-polynomial oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SOURCE_URL not in readme or SOURCE_URL not in rights
            or "residue-block" not in readme
            or "clean-room" not in rights
            or "naive.cpp" not in readme):
        raise ValueError("README or rights note omits kernel/provenance")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "stirling_number_of_the_first_kind_small_p_large_n" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link is missing: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
