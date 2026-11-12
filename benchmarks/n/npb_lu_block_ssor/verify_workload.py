"""Static contract and dual-oracle checks for the NPB LU block SSOR package."""

from __future__ import annotations

import json
import math
import struct
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
import npb_lu_block_ssor_oracle as primary  # noqa: E402
import npb_lu_block_ssor_verifier_oracle as independent  # noqa: E402

SPEC_URL = "https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf"
PORTS = (
    "c/n/npb_lu_block_ssor.c", "c3/n/npb_lu_block_ssor.c3",
    "cpp/n/npb_lu_block_ssor.cpp", "elisa/n/npb_lu_block_ssor.elisa",
    "mojo/n/npb_lu_block_ssor.mojo", "nim/n/npb_lu_block_ssor.nim",
    "odin/n/npb_lu_block_ssor.odin", "rust/n/npb_lu_block_ssor.rs",
    "v/n/npb_lu_block_ssor.v", "zig/n/npb_lu_block_ssor.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "npb_lu_block_ssor"
            or workload.get("function_symbol") != "npb_lu_block_ssor"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("url") != SPEC_URL
            or not source.get("reference", "").endswith("§3.3.2")):
        raise ValueError("workload identity or NASA source attribution is incomplete")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("kind") != "signed_64_bit_integer_array"
            or output_spec.get("kind") != "float64_records"
            or input_spec.get("maximum_input_length") != primary.MAX_INPUT_LENGTH
            or input_spec.get("maximum_grid_points") != primary.MAX_POINTS
            or input_spec.get("dimension_range") != [1, primary.MAX_AXIS]
            or input_spec.get("sweeps_range") != [1, primary.MAX_SWEEPS]
            or output_spec.get("absolute_tolerance") != 1e-8
            or output_spec.get("relative_tolerance") != 1e-8
            or output_spec.get("maximum_output_bytes") != primary.MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != 20480):
        raise ValueError("workload bounds or tolerances differ from the primary oracle")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SPEC_URL not in readme or "PDE-derived coefficients" not in readme
            or "clean-room" not in rights or "do not copy" not in rights):
        raise ValueError("README or rights note omits profile scope or provenance")
    if len(PORTS) != 10:
        raise ValueError("checker must list nine standard ports plus Mojo")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file() or "npb_lu_block_ssor" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link is missing: {relative}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    required_ids = {
        "two-point-coupled-seven-block-ssor", "dense-diagonal-block-solve",
        "nonsymmetric-diagonal-block-invalid", "short-output-capacity",
        "null-input", "null-output",
    }
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        options = {
            "input_length": case.get("input_length"),
            "input_is_null": case.get("input_is_null", False),
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
        }
        first_status, first_output = primary.expected_output(values, **options)
        second_status, second_output = independent.expected_output(values, **options)
        if first_status != second_status or case.get("expected_result") != first_status:
            raise ValueError(f"oracle status mismatch: {case['id']}")
        expected = case.get("expected_output")
        if first_status < 0:
            if first_output or second_output or expected != []:
                raise ValueError(f"error fixture must have no output: {case['id']}")
        else:
            if not independent.validate_output(values, first_output, **options):
                raise ValueError(f"primary output fails dense verifier: {case['id']}")
            actual = struct.unpack("<" + "d" * (first_status // 8), first_output)
            alternate = struct.unpack("<" + "d" * (second_status // 8), second_output)
            if len(expected) != len(actual):
                raise ValueError(f"fixture output length mismatch: {case['id']}")
            for index, (a, b, e) in enumerate(zip(actual, alternate, expected)):
                tolerance = 1e-8 + 1e-8 * abs(b)
                if (not math.isfinite(a) or abs(a - b) > tolerance
                        or abs(a - e) > tolerance):
                    raise ValueError(f"fixture value mismatch at {case['id']}[{index}]")
        if case.get("input_length") != len(values):
            raise ValueError(f"fixture input framing differs: {case['id']}")
    if not required_ids.issubset(seen):
        raise ValueError(f"workload omits required fixtures: {sorted(required_ids - seen)}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
