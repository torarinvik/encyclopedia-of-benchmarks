"""Static contract, fixture, provenance, and port-path checker."""

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from hjm_forward_path_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_LENGTH,
    expected_output,
    independent_output,
)

REPORT_URL = "https://www.cs.princeton.edu/techreports/2010/890.pdf"
SOURCE_URL = "https://github.com/cirosantilli/parsec-benchmark/tree/master/pkgs/apps/swaptions/src"
PORTS = (
    "c/m/hjm_forward_path.c",
    "c3/m/hjm_forward_path.c3",
    "cpp/m/hjm_forward_path.cpp",
    "elisa/m/hjm_forward_path.elisa",
    "mojo/m/hjm_forward_path.mojo",
    "nim/m/hjm_forward_path.nim",
    "odin/m/hjm_forward_path.odin",
    "rust/m/hjm_forward_path.rs",
    "v/m/hjm_forward_path.v",
    "zig/m/hjm_forward_path.zig",
)


def _close_vectors(left: list[float], right: list[float]) -> bool:
    return (len(left) == len(right)
            and all(math.isclose(a, b, rel_tol=1e-12,
                                 abs_tol=ABSOLUTE_TOLERANCE)
                    for a, b in zip(left, right)))


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    contract = workload.get("contract", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "hjm_forward_path"
            or workload.get("function_symbol") != "hjm_forward_path"
            or workload.get("abi") != "float64_slice_io"
            or source.get("report_url") != REPORT_URL
            or source.get("source_url") != SOURCE_URL
            or source.get("kernel") != "HJM_SimPath_Forward_Blocking"
            or contract.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or contract.get("output_encoding") != "Full n-by-n path matrix, flattened row-major; inactive triangular cells are zero."):
        raise ValueError("workload identity, contract, or source attribution differs from review")
    if workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_LENGTH:
        raise ValueError("workload maximum output differs from the oracle")
    if workload.get("workspace", {}).get("elements") != MAX_OUTPUT_LENGTH:
        raise ValueError("workload workspace differs from the maximum path matrix")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
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
        primary = expected_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        if (case.get("input_length") != len(values) and not case.get("input_is_null", False)):
            raise ValueError(f"fixture input length is inconsistent: {case['id']}")
        if primary[0] != case.get("expected_result"):
            raise ValueError(f"fixture result differs from oracle: {case['id']}")
        expected = case.get("expected_output")
        if not isinstance(expected, list) or not _close_vectors(primary[1], expected):
            raise ValueError(f"fixture output differs from oracle: {case['id']}")
        if independent[0] != primary[0] or not _close_vectors(independent[1], primary[1]):
            raise ValueError(f"independent drift oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if REPORT_URL not in readme or SOURCE_URL not in readme:
        raise ValueError("README omits primary source links")
    if "clean-room" not in rights or "Intel Corp." not in rights:
        raise ValueError("rights note omits clean-room and upstream notice context")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "hjm_forward_path" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
