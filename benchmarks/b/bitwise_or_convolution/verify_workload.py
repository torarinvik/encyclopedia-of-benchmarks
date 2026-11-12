"""Static workload, independent-oracle, and ten-port path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from bitwise_or_convolution_oracle import (  # noqa: E402
    MAX_N, MAX_SIZE, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES,
    MAX_WORKSPACE_BYTES, expected_output,
)
from bitwise_or_convolution_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

PORTS = (
    "c/b/bitwise_or_convolution.c",
    "c3/b/bitwise_or_convolution.c3",
    "cpp/b/bitwise_or_convolution.cpp",
    "elisa/b/bitwise_or_convolution.elisa",
    "mojo/b/bitwise_or_convolution.mojo",
    "nim/b/bitwise_or_convolution.nim",
    "odin/b/bitwise_or_convolution.odin",
    "rust/b/bitwise_or_convolution.rs",
    "v/b/bitwise_or_convolution.v",
    "zig/b/bitwise_or_convolution.zig",
)
REFERENCES = (
    "https://neelmishra.github.io/blog/cp/algebra/convolution-variants.html",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "bitwise_or_convolution"
            or workload.get("function_symbol") != "bitwise_or_convolution"
            or workload.get("abi") != "i64_array_bytes_output"):
        raise ValueError("workload identity differs from the package")
    source = workload.get("source", {})
    if source.get("library_checker_task") is not False or any(
            ref not in source.get("references", []) for ref in REFERENCES):
        raise ValueError("general-reference provenance is incomplete")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("n_range") != [0, MAX_N]
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the bounded contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in seen:
            raise ValueError("fixture IDs must be unique named objects")
        seen.add(case["id"])
        values = case.get("input_values", [])
        args = (values, case.get("output_capacity"), case.get("output_is_null", False),
                case.get("input_is_null", False), case.get("input_length"))
        primary = expected_output(*args)
        independent = independent_output(*args)
        if (case.get("input_length") != len(values) or primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex", "").lower()):
            raise ValueError(f"fixture differs from its oracles: {case['id']}")

    maximum = [MAX_N] + [1] * (2 * MAX_SIZE)
    primary = expected_output(maximum, MAX_OUTPUT_BYTES)
    independent = independent_output(maximum, MAX_OUTPUT_BYTES)
    expected = b"".join((pow(3, k.bit_count(), 998244353)).to_bytes(8, "little", signed=True)
                        for k in range(MAX_SIZE))
    if primary != independent or primary != (MAX_OUTPUT_BYTES, expected):
        raise ValueError("maximum all-ones result differs from 3^popcount(k)")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if any(ref not in readme for ref in REFERENCES) or "clean-room" not in rights:
        raise ValueError("README or rights notice omits provenance")
    if len(PORTS) != 10:
        raise ValueError("checker must list ten language ports")
    for relative in PORTS:
        port = ROOT / relative
        if not port.is_file() or "bitwise_or_convolution" not in port.read_text(encoding="utf-8"):
            raise ValueError(f"missing port or symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README omits port path: {relative}")
    return len(cases)
