"""Static workload, dual-oracle, provenance, and port-path checker."""

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from splash2_fft_six_step_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS,
    RELATIVE_TOLERANCE,
    expected_output,
)
from splash2_fft_six_step_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

SOURCE_URL = "https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/kernels/fft/fft.C"
README_URL = "https://github.com/staceyson/splash2/blob/be64f8e4840fc29ff4c076c3f747e27fdb55ac68/codes/kernels/fft/README.fft"
PORTS = (
    "c/f/splash2_fft_six_step.c",
    "c3/f/splash2_fft_six_step.c3",
    "cpp/f/splash2_fft_six_step.cpp",
    "elisa/f/splash2_fft_six_step.elisa",
    "mojo/f/splash2_fft_six_step.mojo",
    "nim/f/splash2_fft_six_step.nim",
    "odin/f/splash2_fft_six_step.odin",
    "rust/f/splash2_fft_six_step.rs",
    "v/f/splash2_fft_six_step.v",
    "zig/f/splash2_fft_six_step.zig",
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
            or workload.get("algorithm") != "splash2_fft_six_step"
            or workload.get("function_symbol") != "splash2_fft_six_step"
            or workload.get("abi") != "float64_slice_io"
            or source.get("url") != SOURCE_URL
            or source.get("readme_path") != "codes/kernels/fft/README.fft"
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or workload.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or workload.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE):
        raise ValueError("workload identity, contract bounds, or source attribution differs")

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
            raise ValueError(f"fixture result differs from direct DFT oracle: {case['id']}")
        expected = case.get("expected_output")
        if not isinstance(expected, list) or not _close_vectors(primary[1], expected):
            raise ValueError(f"fixture output differs from direct DFT oracle: {case['id']}")
        if independent[0] != primary[0] or not _close_vectors(independent[1], primary[1]):
            raise ValueError(f"independent matrix oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or README_URL not in readme:
        raise ValueError("README omits pinned SPLASH-2 sources")
    if "non-commercial" not in rights or "clean-room" not in rights:
        raise ValueError("rights note omits upstream terms or clean-room statement")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "splash2_fft_six_step" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
