"""Static workload, dual-oracle, source, and port-path checker."""

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from npb_mg_vcycle_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE,
    RELATIVE_TOLERANCE,
    expected_output,
)
from npb_mg_vcycle_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

SOURCE_URL = "https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf"
PORTS = (
    "c/n/npb_mg_vcycle.c",
    "c3/n/npb_mg_vcycle.c3",
    "cpp/n/npb_mg_vcycle.cpp",
    "elisa/n/npb_mg_vcycle.elisa",
    "mojo/n/npb_mg_vcycle.mojo",
    "nim/n/npb_mg_vcycle.nim",
    "odin/n/npb_mg_vcycle.odin",
    "rust/n/npb_mg_vcycle.rs",
    "v/n/npb_mg_vcycle.v",
    "zig/n/npb_mg_vcycle.zig",
)


def _close_vectors(left: list[float], right: list[float]) -> bool:
    return (len(left) == len(right)
            and all(math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE,
                                 abs_tol=ABSOLUTE_TOLERANCE)
                    for a, b in zip(left, right)))


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "npb_mg_vcycle"
            or workload.get("function_symbol") != "npb_mg_vcycle"
            or workload.get("abi") != "float64_slice_io"
            or source.get("section") != "2.2.4"
            or source.get("url") != SOURCE_URL
            or workload.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or workload.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE):
        raise ValueError("workload identity, bounds, or NASA attribution differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_length": case.get("input_length"),
            "input_is_null": case.get("input_is_null", False),
        }
        if case.get("input_length") != len(values) and not case.get("input_is_null", False):
            raise ValueError(f"fixture input length is inconsistent: {case['id']}")
        primary = expected_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        if primary[0] != case.get("expected_result"):
            raise ValueError(f"fixture result differs from direct oracle: {case['id']}")
        expected = case.get("expected_output")
        if not isinstance(expected, list) or not _close_vectors(primary[1], expected):
            raise ValueError(f"fixture output differs from direct oracle: {case['id']}")
        if independent[0] != primary[0] or not _close_vectors(independent[1], primary[1]):
            raise ValueError(f"independent matrix oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        raise ValueError("README or rights note omits the official report")
    if "clean-room" not in rights or "does not" not in rights:
        raise ValueError("rights note does not document independent implementation")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "npb_mg_vcycle" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
