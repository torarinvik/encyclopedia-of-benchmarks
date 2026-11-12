"""Static workload, independent-oracle, rights, and ten-port path checks."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
if __package__:
    from .independent_oracle import expected_output as independent_output
    from .oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output
else:
    sys.path.insert(0, str(PACKAGE))
    from independent_oracle import expected_output as independent_output  # noqa: E402
    from oracle import (  # noqa: E402
        MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output,
    )

ALGORITHM = "chromatic_polynomial"
SOURCE_PATHS = (
    "c/c/chromatic_polynomial.c", "c3/c/chromatic_polynomial.c3",
    "cpp/c/chromatic_polynomial.cpp", "elisa/c/chromatic_polynomial.elisa",
    "mojo/c/chromatic_polynomial.mojo", "nim/c/chromatic_polynomial.nim",
    "odin/c/chromatic_polynomial.odin", "rust/c/chromatic_polynomial.rs",
    "v/c/chromatic_polynomial.v", "zig/c/chromatic_polynomial.zig",
)
EXPECTED_CASE_IDS = {
    "zero-vertex-empty-graph", "edgeless-four-vertices", "single-edge", "triangle",
    "three-vertex-path", "four-cycle", "disconnected-two-edges", "complete-four-vertices",
    "invalid-vertex-count", "invalid-edge-count", "self-loop", "duplicate-undirected-edge",
    "endpoint-out-of-range", "truncated-edge-pair", "trailing-input-word",
    "short-output-capacity", "null-output", "null-input",
}


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    cases = workload.get("cases")
    if (workload.get("schema_version") != 1
            or workload.get("id") != "chromatic-polynomial-deletion-contraction-bounded-v1"
            or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
            or not isinstance(cases, list)
            or {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASE_IDS
            or len(cases) != len(EXPECTED_CASE_IDS)):
        raise ValueError("workload identity, bounds, or fixtures differ from the reviewed contract")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture id: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        null_output = case.get("output_is_null", False)
        null_input = case.get("input_is_null", False)
        length = case.get("input_length")
        primary = expected_output(values, capacity, null_output, null_input, length)
        independent = independent_output(values, capacity, null_output, null_input, length)
        if (case.get("input_length") != len(values)
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")
                or independent != primary):
            raise ValueError(f"fixture differs between deletion-contraction and subset oracles: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if ("GSM210.pdf" not in readme or "ChromaticPolynomial.html" not in readme
            or "NetworkX" not in readme or "no upstream code" not in rights):
        raise ValueError("README or rights note omits mathematical provenance or reuse statement")
    for relative in SOURCE_PATHS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port or exported function is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")

    edge_list = [
        (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
        (1, 2), (1, 3), (1, 4), (1, 5), (2, 3),
        (2, 4), (2, 5), (3, 4), (3, 5), (4, 5), (6, 7),
    ]
    maximum = (8, len(edge_list), *(endpoint for edge in edge_list for endpoint in edge))
    if len(maximum) != MAX_INPUT_LENGTH:
        raise ValueError("maximum-shape graph does not match the input bound")
    if expected_output(maximum)[0] < 0 or independent_output(maximum)[0] < 0:
        raise ValueError("maximum-shape graph is rejected by an oracle")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(SOURCE_PATHS)} port paths")
