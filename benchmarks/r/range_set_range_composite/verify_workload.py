"""Package-local static workload, oracle, rights, and port-path checker."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from range_set_range_composite_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_WORKSPACE_BYTES,
    expected_output,
)

ALGORITHM = "range_set_range_composite"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_set_range_composite/task.md"
INFO_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_set_range_composite/info.toml"
PORTS = (
    "c/r/range_set_range_composite.c",
    "c3/r/range_set_range_composite.c3",
    "cpp/r/range_set_range_composite.cpp",
    "elisa/r/range_set_range_composite.elisa",
    "mojo/r/range_set_range_composite.mojo",
    "nim/r/range_set_range_composite.nim",
    "odin/r/range_set_range_composite.odin",
    "rust/r/range_set_range_composite.rs",
    "v/r/range_set_range_composite.v",
    "zig/r/range_set_range_composite.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL
            or workload.get("source", {}).get("limits_url") != INFO_URL
            or workload.get("source", {}).get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or source provenance differs from the reviewed task")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if (input_meta.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or input_meta.get("maximum_valid_length") != MAX_INPUT_LENGTH - 1
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the primary oracle")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture id: {case['id']}")
        seen.add(case["id"])
        result, payload = expected_output(
            case.get("input_values"), case.get("output_capacity"),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case.get("input_length"))
        if (case.get("input_length") != len(case.get("input_values", []))
                or result != case.get("expected_result")
                or payload.hex() != case.get("expected_output_hex")):
            raise ValueError(f"fixture differs from direct-array oracle: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache-2.0" not in rights:
        raise ValueError("README or rights note omits source attribution")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or ALGORITHM not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or exported symbol is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link the port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} workload fixtures and {len(PORTS)} port paths")
