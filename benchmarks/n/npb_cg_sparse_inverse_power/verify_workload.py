"""Static bounds, provenance, port, and oracle-agreement checks for NPB CG."""

from __future__ import annotations

import json
import math
from pathlib import Path
import struct
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
import npb_cg_sparse_inverse_power_oracle as primary  # noqa: E402
import npb_cg_sparse_inverse_power_verifier_oracle as independent  # noqa: E402

SPEC_URL = "https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf"
PORTS = (
    "c/n/npb_cg_sparse_inverse_power.c",
    "c3/n/npb_cg_sparse_inverse_power.c3",
    "cpp/n/npb_cg_sparse_inverse_power.cpp",
    "elisa/n/npb_cg_sparse_inverse_power.elisa",
    "mojo/n/npb_cg_sparse_inverse_power.mojo",
    "nim/n/npb_cg_sparse_inverse_power.nim",
    "odin/n/npb_cg_sparse_inverse_power.odin",
    "rust/n/npb_cg_sparse_inverse_power.rs",
    "v/n/npb_cg_sparse_inverse_power.v",
    "zig/n/npb_cg_sparse_inverse_power.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "npb_cg_sparse_inverse_power"
            or workload.get("function_symbol") != "npb_cg_sparse_inverse_power"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SPEC_URL
            or workload.get("source", {}).get("reference", "").endswith("§2.2.3") is False):
        raise ValueError("workload identity or NASA source attribution is incomplete")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    if (input_contract.get("maximum_input_length") != primary.MAX_INPUT_LENGTH
            or input_contract.get("dimension_range") != [1, primary.MAX_N]
            or input_contract.get("outer_iterations_range") != [1, primary.MAX_OUTER_ITERATIONS]
            or input_contract.get("cg_steps_upper_bound") != "min(25,n)"
            or output_contract.get("max_output_bytes") != primary.MAX_OUTPUT_BYTES
            or output_contract.get("absolute_tolerance") != primary.ABSOLUTE_TOLERANCE
            or output_contract.get("relative_tolerance") != primary.RELATIVE_TOLERANCE):
        raise ValueError("workload bounds differ from the primary oracle")
    if len(PORTS) != 10:
        raise ValueError("the package checker must list the nine standard ports and Mojo")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SPEC_URL not in readme or "makea" not in readme or "clean-room" not in rights
            or "does not include the canonical `makea` generator" not in rights):
        raise ValueError("README or rights note omits bounded scope or provenance")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "npb_cg_sparse_inverse_power" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link is missing: {relative}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    required_ids = {
        "sparse-off-diagonal-two-outer-steps", "two-eigenvalues-two-cg-steps",
        "nonzero-estimate-shift", "nonsymmetric-matrix-invalid",
        "nonpositive-diagonal-invalid", "malformed-row-pointer-invalid",
        "short-output-capacity", "null-output", "null-input",
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
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        first_status, first_bytes = primary.expected_output(values, **options)
        second_status, second_bytes = independent.expected_output(values, **options)
        if first_status != second_status or case.get("expected_result") != first_status:
            raise ValueError(f"oracle status mismatch: {case['id']}")
        expected_values = case.get("expected_output")
        if first_status < 0:
            if first_bytes or second_bytes or expected_values != []:
                raise ValueError(f"error fixture should have empty output: {case['id']}")
        else:
            if not independent.validate_output(values, first_bytes, **options):
                raise ValueError(f"primary output fails the independent certificate: {case['id']}")
            actual = struct.unpack("<" + "d" * (first_status // 8), first_bytes)
            reference = struct.unpack("<" + "d" * (second_status // 8), second_bytes)
            if len(expected_values) != len(actual):
                raise ValueError(f"fixture output length mismatch: {case['id']}")
            for index, (actual_value, independent_value, fixture_value) in enumerate(
                    zip(actual, reference, expected_values)):
                tolerance = primary.ABSOLUTE_TOLERANCE + primary.RELATIVE_TOLERANCE * abs(independent_value)
                if (not math.isfinite(actual_value)
                        or abs(actual_value - independent_value) > tolerance
                        or abs(actual_value - fixture_value) > tolerance):
                    raise ValueError(f"fixture value mismatch at {case['id']}[{index}]")
        if case.get("input_length") != len(values):
            raise ValueError(f"fixture length framing differs: {case['id']}")
    if not required_ids.issubset(seen):
        raise ValueError(f"workload omits required cases: {sorted(required_ids - seen)}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")

