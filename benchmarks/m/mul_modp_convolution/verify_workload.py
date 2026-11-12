"""Static workload, source, oracle-agreement, and ten-port path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from mul_modp_convolution_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES, expected_output,
)
from mul_modp_convolution_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/convolution/mul_modp_convolution/task.md"
INFO_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/mul_modp_convolution/info.toml"
PORTS = (
    "c/m/mul_modp_convolution.c",
    "c3/m/mul_modp_convolution.c3",
    "cpp/m/mul_modp_convolution.cpp",
    "elisa/m/mul_modp_convolution.elisa",
    "mojo/m/mul_modp_convolution.mojo",
    "nim/m/mul_modp_convolution.nim",
    "odin/m/mul_modp_convolution.odin",
    "rust/m/mul_modp_convolution.rs",
    "v/m/mul_modp_convolution.v",
    "zig/m/mul_modp_convolution.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "mul_modp_convolution"
            or workload.get("function_symbol") != "mul_modp_convolution"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != INFO_URL
            or source.get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or source attribution differs from reviewed task")
    if (workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH - 1
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the primary oracle")
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
        primary = expected_output(values, case.get("output_capacity"),
                                  case.get("output_is_null", False), False,
                                  case.get("input_length"))
        independent = independent_output(values, case.get("output_capacity"),
                                         case.get("output_is_null", False), False,
                                         case.get("input_length"))
        if (case.get("input_length") != len(values)
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")
                or independent != primary):
            raise ValueError(f"fixture differs between independent oracles: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache-2.0" not in rights:
        raise ValueError("README or rights note omits provenance")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "mul_modp_convolution" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
