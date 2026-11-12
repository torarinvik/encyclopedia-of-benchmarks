"""Static workload, provenance, direct-oracle, and port-path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from bitwise_xor_convolution_oracle import (  # noqa: E402
    MAX_N, MAX_SIZE, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES,
    MAX_WORKSPACE_BYTES, expected_output,
)
from bitwise_xor_convolution_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/convolution/bitwise_xor_convolution/task.md"
INFO_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/bitwise_xor_convolution/info.toml"
PORTS = (
    "c/b/bitwise_xor_convolution.c",
    "c3/b/bitwise_xor_convolution.c3",
    "cpp/b/bitwise_xor_convolution.cpp",
    "elisa/b/bitwise_xor_convolution.elisa",
    "mojo/b/bitwise_xor_convolution.mojo",
    "nim/b/bitwise_xor_convolution.nim",
    "odin/b/bitwise_xor_convolution.odin",
    "rust/b/bitwise_xor_convolution.rs",
    "v/b/bitwise_xor_convolution.v",
    "zig/b/bitwise_xor_convolution.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "bitwise_xor_convolution"
            or workload.get("function_symbol") != "bitwise_xor_convolution"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != INFO_URL
            or source.get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or provenance differs from the reviewed task")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("n_range") != [0, MAX_N]
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the bounded profile")
    generated = workload.get("generated_profile", {})
    if (generated.get("maximum_n") != MAX_N
            or generated.get("maximum_input") != "[8, 256 copies of 1, 256 copies of 1]"
            or generated.get("maximum_output") != "256 copies of 256"
            or generated.get("expected_output_bytes") != MAX_OUTPUT_BYTES):
        raise ValueError("maximum profile description differs from the bounded contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    required_ids = {
        "zero-bit-domain", "one-bit-mixed-coefficients", "two-bit-dense-coefficients",
        "three-bit-impulse-shift", "domain-size-above-bound", "truncated-frame",
        "extra-word-frame", "coefficient-at-modulus", "negative-coefficient",
        "malformed-before-capacity", "short-output-capacity", "null-output", "null-input",
    }
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        args = (values, case.get("output_capacity"),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
        primary = expected_output(*args)
        independent = independent_output(*args)
        if (case.get("input_length") != len(values)
                or primary != independent
                or primary[0] != case.get("expected_result")):
            raise ValueError(f"fixture differs between direct oracles: {case['id']}")
        if "expected_output_hex" in case and primary[1].hex() != case["expected_output_hex"].lower():
            raise ValueError(f"fixture bytes differ from the pinned output: {case['id']}")
        if primary[0] >= 0 and len(primary[1]) != primary[0]:
            raise ValueError(f"fixture result does not match its byte payload: {case['id']}")
        if primary[0] < 0 and primary[1]:
            raise ValueError(f"error fixture contains output bytes: {case['id']}")
    if not required_ids.issubset(seen):
        raise ValueError(f"workload omits required cases: {sorted(required_ids - seen)}")

    maximum = [MAX_N] + [1] * (2 * MAX_SIZE)
    max_primary = expected_output(maximum, MAX_OUTPUT_BYTES)
    max_independent = independent_output(maximum, MAX_OUTPUT_BYTES)
    expected_max = b"".join((MAX_SIZE).to_bytes(8, "little", signed=True)
                            for _ in range(MAX_SIZE))
    if (max_primary != max_independent or max_primary[0] != MAX_OUTPUT_BYTES
            or max_primary[1] != expected_max):
        raise ValueError("maximum all-ones profile differs from the direct convolution formula")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache-2.0" not in rights:
        raise ValueError("README or rights note omits provenance")
    if len(PORTS) != 10:
        raise ValueError("the package checker must list all ten language ports")
    for relative in PORTS:
        port = ROOT / relative
        if (not port.is_file()
                or "bitwise_xor_convolution" not in port.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link is missing: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
