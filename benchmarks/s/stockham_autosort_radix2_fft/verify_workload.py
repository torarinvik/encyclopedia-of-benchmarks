"""Static workload, dual-oracle, provenance, and port-path checker."""

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from s.stockham_autosort_radix2_fft.independent_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH as INDEPENDENT_MAX_INPUT_LENGTH,
    expected_output as independent_output,
)
from s.stockham_autosort_radix2_fft.primary_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS,
    MAX_VALID_INPUT_LENGTH,
    RELATIVE_TOLERANCE,
    WORKSPACE_ELEMENTS,
    expected_output,
)

SOURCE_URL = "https://doi.org/10.1145/1464182.1464209"
PORTS = (
    "c/s/stockham_autosort_radix2_fft.c",
    "c3/s/stockham_autosort_radix2_fft.c3",
    "cpp/s/stockham_autosort_radix2_fft.cpp",
    "elisa/s/stockham_autosort_radix2_fft.elisa",
    "mojo/s/stockham_autosort_radix2_fft.mojo",
    "nim/s/stockham_autosort_radix2_fft.nim",
    "odin/s/stockham_autosort_radix2_fft.odin",
    "rust/s/stockham_autosort_radix2_fft.rs",
    "v/s/stockham_autosort_radix2_fft.v",
    "zig/s/stockham_autosort_radix2_fft.zig",
)


def _close_vectors(left: list[float], right: list[float]) -> bool:
    return (len(left) == len(right)
            and all(math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE,
                                 abs_tol=ABSOLUTE_TOLERANCE)
                    for a, b in zip(left, right)))


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "stockham_autosort_radix2_fft"
            or workload.get("function_symbol") != "stockham_autosort_radix2_fft"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or INDEPENDENT_MAX_INPUT_LENGTH != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or workload.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or workload.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE
            or workload.get("workspace", {}).get("elements") != WORKSPACE_ELEMENTS):
        raise ValueError("workload identity or bounds differ from the Stockham profile")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    maximum_case = next((case for case in cases
                         if isinstance(case, dict)
                         and case.get("id") == "maximum-size-zero-transform"), None)
    if (maximum_case is None
            or maximum_case.get("input_length") != MAX_VALID_INPUT_LENGTH
            or maximum_case.get("expected_result") != MAX_OUTPUT_ELEMENTS
            or len(maximum_case.get("expected_output", [])) != MAX_OUTPUT_ELEMENTS):
        raise ValueError("workload omits the maximum-length Stockham case")
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
        if case.get("input_length") != len(values) and not case.get("input_is_null", False):
            raise ValueError(f"fixture input length is inconsistent: {case['id']}")
        expected = case.get("expected_output")
        if (primary[0] != case.get("expected_result")
                or not isinstance(expected, list)
                or not _close_vectors(primary[1], expected)):
            raise ValueError(f"fixture differs from the Stockham stage oracle: {case['id']}")
        if independent[0] != primary[0] or not _close_vectors(independent[1], primary[1]):
            raise ValueError(f"direct DFT oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "clean-room" not in rights:
        raise ValueError("README or rights note omits source attribution")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or "stockham_autosort_radix2_fft" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
