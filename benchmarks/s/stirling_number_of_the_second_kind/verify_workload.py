"""Static dual-oracle, metadata, rights, and ten-port package checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))

from stirling_number_of_the_second_kind_oracle import (  # noqa: E402
    MAX_N,
    MODULUS,
    expected_result,
)
from stirling_number_of_the_second_kind_verifier_oracle import (  # noqa: E402
    expected_result as independent_result,
)

SOURCE_URL = (
    "https://github.com/yosupo06/library-checker-problems/blob/master/"
    "enumerative_combinatorics/stirling_number_of_the_second_kind/task.md"
)
PORTS = (
    "c/s/stirling_number_of_the_second_kind.c",
    "c3/s/stirling_number_of_the_second_kind.c3",
    "cpp/s/stirling_number_of_the_second_kind.cpp",
    "elisa/s/stirling_number_of_the_second_kind.elisa",
    "mojo/s/stirling_number_of_the_second_kind.mojo",
    "nim/s/stirling_number_of_the_second_kind.nim",
    "odin/s/stirling_number_of_the_second_kind.odin",
    "rust/s/stirling_number_of_the_second_kind.rs",
    "v/s/stirling_number_of_the_second_kind.v",
    "zig/s/stirling_number_of_the_second_kind.zig",
)


def verify_workload():
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "stirling_number_of_the_second_kind"
            or workload.get("function_symbol") != "stirling_number_of_the_second_kind"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("N_range") != [0, MAX_N]
            or workload.get("output", {}).get("formula")
            != "sum((k+1)^3*S(N,k)) mod 998244353"
            or workload.get("contract", {}).get("official_modulus") != MODULUS
            or workload.get("contract", {}).get("official_N_range") != [0, 500000]):
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
        if (not isinstance(values, list)
                or case.get("input_length") != len(values)):
            raise ValueError(f"fixture input frame differs: {case['id']}")
        primary = expected_result(values)
        independent = independent_result(values)
        if primary != case.get("expected_result"):
            raise ValueError(f"fixture differs from recurrence oracle: {case['id']}")
        if independent != primary:
            raise ValueError(f"inclusion-exclusion oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SOURCE_URL not in readme or SOURCE_URL not in rights
            or "Bell-triangle" not in readme
            or "integer partitions" not in readme
            or "clean-room" not in rights):
        raise ValueError("README or rights note omits contract/distinctness/provenance")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "stirling_number_of_the_second_kind" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link is missing: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
