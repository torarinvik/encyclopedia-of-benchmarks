"""Static workload, oracle, attribution, and ten-port path check."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from range_reverse_range_sum_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES, expected_output,
)
from range_reverse_range_sum_verifier_oracle import expected_output as verifier_output  # noqa: E402

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_reverse_range_sum/task.md"
INFO_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_reverse_range_sum/info.toml"
PORTS = (
    "c/r/range_reverse_range_sum.c", "c3/r/range_reverse_range_sum.c3",
    "cpp/r/range_reverse_range_sum.cpp", "elisa/r/range_reverse_range_sum.elisa",
    "mojo/r/range_reverse_range_sum.mojo", "nim/r/range_reverse_range_sum.nim",
    "odin/r/range_reverse_range_sum.odin", "rust/r/range_reverse_range_sum.rs",
    "v/r/range_reverse_range_sum.v", "zig/r/range_reverse_range_sum.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "range_reverse_range_sum"
            or workload.get("function_symbol") != "range_reverse_range_sum"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL
            or workload.get("source", {}).get("limits_url") != INFO_URL
            or workload.get("source", {}).get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or source attribution differs from the reviewed task")
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
        result, output = expected_output(
            values, case.get("output_capacity"), case.get("output_is_null", False),
            case.get("input_is_null", False), case.get("input_length"))
        verifier_result, verifier_bytes = verifier_output(
            values, case.get("output_capacity"), case.get("output_is_null", False),
            case.get("input_is_null", False), case.get("input_length"))
        if (case.get("input_length") != len(values)
                or result != case.get("expected_result")
                or output.hex() != case.get("expected_output_hex")
                or (verifier_result, verifier_bytes) != (result, output)):
            raise ValueError(f"fixture differs from direct-sequence oracle: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache-2.0" not in rights:
        raise ValueError("README or rights note omits source attribution")
    for relative in PORTS:
        port = ROOT / relative
        if not port.is_file() or "range_reverse_range_sum" not in port.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
