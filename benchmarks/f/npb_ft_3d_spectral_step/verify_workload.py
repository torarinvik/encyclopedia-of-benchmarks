"""Static workload, dual-oracle, provenance, and port-path checker."""

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from npb_ft_3d_spectral_step_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS,
    RELATIVE_TOLERANCE,
    expected_output,
)
from npb_ft_3d_spectral_step_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

SOURCE_URL = "https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf"
PORTS = (
    "c/f/npb_ft_3d_spectral_step.c",
    "c3/f/npb_ft_3d_spectral_step.c3",
    "cpp/f/npb_ft_3d_spectral_step.cpp",
    "elisa/f/npb_ft_3d_spectral_step.elisa",
    "mojo/f/npb_ft_3d_spectral_step.mojo",
    "nim/f/npb_ft_3d_spectral_step.nim",
    "odin/f/npb_ft_3d_spectral_step.odin",
    "rust/f/npb_ft_3d_spectral_step.rs",
    "v/f/npb_ft_3d_spectral_step.v",
    "zig/f/npb_ft_3d_spectral_step.zig",
)


def _close_vectors(left: list[float], right: list[float]) -> bool:
    return (len(left) == len(right)
            and all(math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE,
                                 abs_tol=ABSOLUTE_TOLERANCE)
                    for a, b in zip(left, right)))


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "npb_ft_3d_spectral_step"
            or workload.get("function_symbol") != "npb_ft_3d_spectral_step"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
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
        primary = expected_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        if case.get("input_length") != len(values) and not case.get("input_is_null", False):
            raise ValueError(f"fixture input length is inconsistent: {case['id']}")
        if primary[0] != case.get("expected_result"):
            raise ValueError(f"fixture result differs from direct 3-D DFT oracle: {case['id']}")
        expected = case.get("expected_output")
        if not isinstance(expected, list) or not _close_vectors(primary[1], expected):
            raise ValueError(f"fixture output differs from direct 3-D DFT oracle: {case['id']}")
        if independent[0] != primary[0] or not _close_vectors(independent[1], primary[1]):
            raise ValueError(f"independent separable oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in rights:
        raise ValueError("README or rights note omits NASA attribution and clean-room status")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "npb_ft_3d_spectral_step" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
