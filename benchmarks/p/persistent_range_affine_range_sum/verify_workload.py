"""Static fixture, provenance, oracle-agreement, and port-path checker."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from persistent_range_affine_range_sum_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES,
    MAX_INTERNAL_NODE_POOL_BYTES, expected_output,
)
from persistent_range_affine_range_sum_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_range_affine_range_sum/task.md"
INFO_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/persistent_range_affine_range_sum/info.toml"
PORTS = (
    "c/p/persistent_range_affine_range_sum.c",
    "c3/p/persistent_range_affine_range_sum.c3",
    "cpp/p/persistent_range_affine_range_sum.cpp",
    "elisa/p/persistent_range_affine_range_sum.elisa",
    "mojo/p/persistent_range_affine_range_sum.mojo",
    "nim/p/persistent_range_affine_range_sum.nim",
    "odin/p/persistent_range_affine_range_sum.odin",
    "rust/p/persistent_range_affine_range_sum.rs",
    "v/p/persistent_range_affine_range_sum.v",
    "zig/p/persistent_range_affine_range_sum.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "persistent_range_affine_range_sum"
            or workload.get("function_symbol") != "persistent_range_affine_range_sum"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL
            or workload.get("source", {}).get("limits_url") != INFO_URL
            or workload.get("source", {}).get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or source attribution differs from the reviewed task")
    if (workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH - 1
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or workload.get("workspace", {}).get("internal_node_pool_bytes") != MAX_INTERNAL_NODE_POOL_BYTES):
        raise ValueError("workload bounds differ from the direct oracle")
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
        actual = expected_output(values, case.get("output_capacity"),
                                case.get("output_is_null", False), False,
                                case.get("input_length"))
        independent = independent_output(values, case.get("output_capacity"),
                                         case.get("output_is_null", False), False,
                                         case.get("input_length"))
        if (case.get("input_length") != len(values)
                or actual[0] != case.get("expected_result")
                or actual[1].hex() != case.get("expected_output_hex")
                or independent != actual):
            raise ValueError(f"fixture differs between direct oracles: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache-2.0" not in rights:
        raise ValueError("README or rights note omits source attribution")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "persistent_range_affine_range_sum" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
