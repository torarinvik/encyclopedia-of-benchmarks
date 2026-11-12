"""Static fixture, small-board enumeration, and ten-port checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from broken_profile_domino_tilings_oracle import (  # noqa: E402
    MAX_SIDE, MAX_PROFILE_WIDTH, MAX_AREA, MODULUS, direct_small_result, expected_result,
)
from broken_profile_domino_tilings_verifier_oracle import (  # noqa: E402
    expected_result as independent_result,
)

PORTS = (
    "c/b/broken_profile_domino_tilings.c",
    "c3/b/broken_profile_domino_tilings.c3",
    "cpp/b/broken_profile_domino_tilings.cpp",
    "elisa/b/broken_profile_domino_tilings.elisa",
    "mojo/b/broken_profile_domino_tilings.mojo",
    "nim/b/broken_profile_domino_tilings.nim",
    "odin/b/broken_profile_domino_tilings.odin",
    "rust/b/broken_profile_domino_tilings.rs",
    "v/b/broken_profile_domino_tilings.v",
    "zig/b/broken_profile_domino_tilings.zig",
)
SOURCE_URL = "https://cp-algorithms.com/dynamic_programming/profile-dynamics.html"


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "broken_profile_domino_tilings"
            or workload.get("function_symbol") != "broken_profile_domino_tilings"
            or workload.get("abi") != "i64_array_scalar_call"):
        raise ValueError("workload identity differs from package")
    source = workload.get("source", {})
    if source.get("url") != SOURCE_URL or source.get("license") != "CC BY-SA 4.0":
        raise ValueError("broken-profile attribution/license is missing")
    if (workload.get("input", {}).get("side_range") != [1, MAX_SIDE]
            or workload.get("input", {}).get("maximum_profile_width") != MAX_PROFILE_WIDTH
            or workload.get("input", {}).get("maximum_area") != MAX_AREA
            or workload.get("output", {}).get("modulus") != MODULUS):
        raise ValueError("workload bounds differ from package")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain cases")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in seen:
            raise ValueError("case IDs must be unique")
        seen.add(case["id"])
        values = case.get("input_values")
        primary = expected_result(values)
        independent = independent_result(values)
        if primary != independent or primary != case.get("expected_result"):
            raise ValueError(f"fixture differs from profile oracles: {case['id']}")
        if primary >= 0 and values[0] * values[1] <= 30:
            if direct_small_result(values) != primary:
                raise ValueError(f"direct small-board enumeration mismatch: {case['id']}")
    maximum = [8, 64]
    if expected_result(maximum) != independent_result(maximum):
        raise ValueError("maximum profile differs between row-transition oracles")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "CC BY-SA 4.0" not in rights:
        raise ValueError("README or rights note omits source attribution")
    if len(PORTS) != 10:
        raise ValueError("checker must list all ten ports")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "broken_profile_domino_tilings" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README path missing: {relative}")
    return len(cases)
