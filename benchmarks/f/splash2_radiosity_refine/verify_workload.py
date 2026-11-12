"""Static workload, dual-oracle, rights-note, and port-path checker."""

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from splash2_radiosity_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    RELATIVE_TOLERANCE,
    expected_output,
)
from splash2_radiosity_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

SOURCE_URL = "https://github.com/staceyson/splash2/blob/master/codes/apps/radiosity/rad_main.C"
ALGORITHM_URL = "https://doi.org/10.1145/122718.122740"
PORTS = (
    "c/f/splash2_radiosity_refine.c",
    "c3/f/splash2_radiosity_refine.c3",
    "cpp/f/splash2_radiosity_refine.cpp",
    "elisa/f/splash2_radiosity_refine.elisa",
    "mojo/f/splash2_radiosity_refine.mojo",
    "nim/f/splash2_radiosity_refine.nim",
    "odin/f/splash2_radiosity_refine.odin",
    "rust/f/splash2_radiosity_refine.rs",
    "v/f/splash2_radiosity_refine.v",
    "zig/f/splash2_radiosity_refine.zig",
)


def _close_vectors(left: list[float], right: list[float]) -> bool:
    if len(left) != len(right):
        return False
    for index, (a, b) in enumerate(zip(left, right)):
        if index in (1, 2):
            if a != b:
                return False
        elif not math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE,
                              abs_tol=ABSOLUTE_TOLERANCE):
            return False
    return True


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "splash2_radiosity_refine"
            or workload.get("function_symbol") != "splash2_radiosity_refine"
            or workload.get("abi") != "float64_slice_io"
            or source.get("source_url") != SOURCE_URL
            or source.get("algorithm_reference_url") != ALGORITHM_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or workload.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or workload.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE
            or "heuristic" not in workload.get("contract", {}).get("error_model", "")
            or workload.get("contract", {}).get("maximum_leaf_links") != 4 ** 5):
        raise ValueError("workload identity, bounds, or source attribution differs")

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
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = expected_output(values, **kwargs)
        if case.get("input_length") != len(values) and not case.get("input_is_null", False):
            raise ValueError(f"fixture input length is inconsistent: {case['id']}")
        if primary[0] != case.get("expected_result"):
            raise ValueError(f"fixture result differs from recursive oracle: {case['id']}")
        expected = case.get("expected_output")
        if not isinstance(expected, list) or not _close_vectors(primary[1], expected):
            raise ValueError(f"fixture output differs from recursive oracle: {case['id']}")
        if primary[0] == MAX_OUTPUT_ELEMENTS:
            independent = independent_output(values)
            if independent[0] != primary[0] or not _close_vectors(independent[1], primary[1]):
                raise ValueError(f"independent work-stack oracle disagrees: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or ALGORITHM_URL not in readme:
        raise ValueError("README omits source or published algorithm provenance")
    if ("non-commercial" not in rights or "redistribution" not in rights
            or "clean-room" not in rights or "problem text" not in rights
            or "heuristic" not in rights or "precision guarantee" not in rights
            or "heuristic probe" not in readme or "not a certified" not in readme):
        raise ValueError("rights note omits source restrictions or clean-room scope")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "splash2_radiosity_refine" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or exported entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
