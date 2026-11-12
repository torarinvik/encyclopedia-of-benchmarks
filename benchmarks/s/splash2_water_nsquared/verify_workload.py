"""Static workload, oracle, provenance, and ten-port checks."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from splash2_water_nsquared_oracle import (  # noqa: E402
    MAX_PARSEABLE_INPUT_VALUES, MAX_OUTPUT_BYTES, expected_output,
)
from water_spatial_verifier_oracle import expected_output as independent_expected_output  # noqa: E402

PORTS = tuple(
    f"{language}/s/splash2_water_nsquared.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "splash2_water_nsquared"
            or workload.get("function_symbol") != "splash2_water_nsquared"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_parseable_input_values")
                != MAX_PARSEABLE_INPUT_VALUES
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
            or workload.get("measurement", {}).get("comparison_model")
                != "i64_array_bytes_output_call"):
        raise ValueError("splash2_water_nsquared workload differs from its bounded byte-output contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("splash2_water_nsquared workload must contain cases")
    ids = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in ids:
            raise ValueError("splash2_water_nsquared case IDs must be unique")
        ids.add(case["id"])
        values = case.get("input_values")
        length = case.get("input_length", len(values) if isinstance(values, list) else None)
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        actual = expected_output(values, capacity, output_is_null, input_is_null, length)
        independent = independent_expected_output(
            values, capacity, output_is_null, input_is_null, length)
        if (actual != independent
                or actual[0] != case.get("expected_result")
                or ("expected_output_hex" in case
                    and (actual[1].hex() if actual[1] else "")
                    != case["expected_output_hex"].replace(" ", "").lower())):
            raise ValueError(f"splash2_water_nsquared fixture disagrees with independent oracles: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if ("not a reproduction of the SPLASH water force field" not in readme
            or workload.get("provenance", {}).get("source_url") not in readme):
        raise ValueError("splash2_water_nsquared README omits projection scope or provenance")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "splash2_water_nsquared" not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"splash2_water_nsquared port or README link is missing: {relative}")
    return len(cases)
