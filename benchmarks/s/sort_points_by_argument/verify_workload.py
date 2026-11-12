"""Static fixtures, exact-oracle agreement, provenance, and port inventory."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
import primary_oracle as primary  # noqa: E402
import independent_oracle as independent  # noqa: E402

SOURCE_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/geo/sort_points_by_argument/task.md"
PORTS = (
    "c/s/sort_points_by_argument.c",
    "c3/s/sort_points_by_argument.c3",
    "cpp/s/sort_points_by_argument.cpp",
    "elisa/s/sort_points_by_argument.elisa",
    "mojo/s/sort_points_by_argument.mojo",
    "nim/s/sort_points_by_argument.nim",
    "odin/s/sort_points_by_argument.odin",
    "rust/s/sort_points_by_argument.rs",
    "v/s/sort_points_by_argument.v",
    "zig/s/sort_points_by_argument.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (
        workload.get("schema_version") != 1
        or workload.get("algorithm") != "sort_points_by_argument"
        or workload.get("function_symbol") != "sort_points_by_argument"
        or workload.get("abi") != "i64_array_bytes_output"
        or workload.get("source", {}).get("article_url") != SOURCE_URL
        or workload.get("input", {}).get("maximum_valid_length") != primary.MAX_INPUT_LENGTH
        or workload.get("input", {}).get("maximum_parseable_input_length") != primary.MAX_INPUT_LENGTH
        or workload.get("output", {}).get("maximum_output_elements") != 2 * primary.MAX_N
        or workload.get("output", {}).get("maximum_bytes") != primary.MAX_OUTPUT_BYTES
        or workload.get("workspace", {}).get("bytes") != primary.MAX_WORKSPACE_BYTES
    ):
        raise ValueError("workload identity, bounds, or source attribution differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture must have a string ID")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            if not case.get("input_is_null", False):
                raise ValueError(f"input framing differs: {case['id']}")
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        actual = primary.expected_output(values, **kwargs)
        alternate = independent.expected_output(values, **kwargs)
        if actual != expected or alternate != actual:
            raise ValueError(f"fixture/oracle disagreement: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in readme:
        raise ValueError("README or rights note omits provenance")
    if len(PORTS) != 10:
        raise ValueError("port inventory must list all ten languages")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or "sort_points_by_argument" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    elisa = (ROOT / PORTS[3]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "mutable view[" not in elisa:
        raise ValueError("Elisa internals must use safe views and fixed arrays")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} port paths")
