"""Package-local static metadata, fixture-oracle, and port-path checker.

This file is supplied for maintainers; it is not run as part of this task.
"""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from static_range_inversions_query_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_WORKSPACE_BYTES,
    expected_output,
)

ALGORITHM = "static_range_inversions_query"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_inversions_query/task.md"
INFO_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/static_range_inversions_query/info.toml"
PORTS = (
    "c/s/static_range_inversions_query.c",
    "c3/s/static_range_inversions_query.c3",
    "cpp/s/static_range_inversions_query.cpp",
    "elisa/s/static_range_inversions_query.elisa",
    "mojo/s/static_range_inversions_query.mojo",
    "nim/s/static_range_inversions_query.nim",
    "odin/s/static_range_inversions_query.odin",
    "rust/s/static_range_inversions_query.rs",
    "v/s/static_range_inversions_query.v",
    "zig/s/static_range_inversions_query.zig",
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
        raise ValueError("workload identity or provenance differs from the reviewed source")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if (input_meta.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or input_meta.get("maximum_valid_length") != MAX_INPUT_LENGTH - 1
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the oracle contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture must be a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture id: {case['id']}")
        seen.add(case["id"])
        result, payload = expected_output(
            case.get("input_values"), case.get("output_capacity"),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case.get("input_length"))
        if result != case.get("expected_result") or payload.hex() != case.get("expected_output_hex"):
            raise ValueError(f"fixture differs from Mo/Fenwick oracle: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache" not in rights:
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
