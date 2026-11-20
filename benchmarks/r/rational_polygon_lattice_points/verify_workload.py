"""Static fixture, source-link, and language-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path
import re

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_PARSEABLE_LENGTH, MAX_VALID_LENGTH, expected_output as primary_output,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_PARSEABLE_LENGTH, MAX_VALID_LENGTH, expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "rational_polygon_lattice_points"
SOURCE_URL = "https://cp-algorithms.com/geometry/lattice-points.html"
PORTS = (
    "c/r/rational_polygon_lattice_points.c",
    "c3/r/rational_polygon_lattice_points.c3",
    "cpp/r/rational_polygon_lattice_points.cpp",
    "elisa/r/rational_polygon_lattice_points.elisa",
    "mojo/r/rational_polygon_lattice_points.mojo",
    "nim/r/rational_polygon_lattice_points.nim",
    "odin/r/rational_polygon_lattice_points.odin",
    "rust/r/rational_polygon_lattice_points.rs",
    "v/r/rational_polygon_lattice_points.v",
    "zig/r/rational_polygon_lattice_points.zig",
)
REQUIRED_FIXTURES = {
    "rational-right-triangle-no-interior-points": 0,
    "clockwise-half-grid-square": 4,
    "integer-x-vertical-boundary": 2,
    "integer-x-single-vertex-column": 1,
    "nonconvex-vertex-order": -1,
}


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("workload identity mismatch")
    input_contract = workload.get("input", {})
    if (input_contract.get("maximum_valid_length") != MAX_VALID_LENGTH
            or input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH):
        raise ValueError("workload length bounds differ from the contract")
    if SOURCE_URL not in workload.get("source", {}).get("urls", []):
        raise ValueError("workload source attribution is incomplete")
    complexity = workload.get("complexity", {})
    if ("integer_vertex_x_columns" not in complexity
            or complexity.get("total") != "O(N^3 + N^2 log C)"):
        raise ValueError("workload complexity omits event-column classification")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixtures require string IDs")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture length mismatch: {case['id']}")
        options = {"input_is_null": case.get("input_is_null", False),
                   "input_length": case.get("input_length")}
        expected = case.get("expected_result")
        if primary_output(values, **options) != expected:
            raise ValueError(f"primary oracle/workload mismatch: {case['id']}")
        if independent_output(values, **options) != expected:
            raise ValueError(f"independent oracle/workload mismatch: {case['id']}")

    by_id = {case["id"]: case for case in cases}
    for case_id, expected in REQUIRED_FIXTURES.items():
        if case_id not in by_id or by_id[case_id].get("expected_result") != expected:
            raise ValueError(f"required geometric fixture is missing or unexpected: {case_id}")

    maximum = next((case for case in cases
                    if case.get("id") == "maximum-valid-rational-octagon"), None)
    if (maximum is None or maximum.get("input_length") != MAX_VALID_LENGTH
            or maximum.get("expected_result") != 0):
        raise ValueError("maximum valid frame is missing or unexpected")
    trailing = next((case for case in cases
                     if case.get("id") == "maximum-parseable-trailing-word"), None)
    if (trailing is None or trailing.get("input_length") != MAX_PARSEABLE_LENGTH
            or trailing.get("expected_result") != -1
            or trailing.get("input_values") != maximum.get("input_values") + [0]):
        raise ValueError("maximum parseable rejection frame is missing")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        raise ValueError("README or RIGHTS omits the primary source")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"missing language port: {relative}")
        if SYMBOL not in source.read_text(encoding="utf-8"):
            raise ValueError(f"missing exported symbol text: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link {relative}")
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", readme):
        if "://" not in target and not (PACKAGE / target).resolve().is_file():
            raise ValueError(f"README target is missing: {target}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
