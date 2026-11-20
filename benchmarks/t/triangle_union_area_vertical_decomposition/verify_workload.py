"""Static package, metadata, and independent-reference consistency checks."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
from primary_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES,
    MAX_WORKSPACE_BYTES, expected_output as primary,
)
from independent_oracle import expected_output as independent  # noqa: E402

SOURCE_URL = "https://cp-algorithms.com/geometry/vertical_decomposition.html"
PORTS = {
    "c": "c/t/triangle_union_area_vertical_decomposition.c",
    "c3": "c3/t/triangle_union_area_vertical_decomposition.c3",
    "cpp": "cpp/t/triangle_union_area_vertical_decomposition.cpp",
    "elisa": "elisa/t/triangle_union_area_vertical_decomposition.elisa",
    "mojo": "mojo/t/triangle_union_area_vertical_decomposition.mojo",
    "nim": "nim/t/triangle_union_area_vertical_decomposition.nim",
    "odin": "odin/t/triangle_union_area_vertical_decomposition.odin",
    "rust": "rust/t/triangle_union_area_vertical_decomposition.rs",
    "v": "v/t/triangle_union_area_vertical_decomposition.v",
    "zig": "zig/t/triangle_union_area_vertical_decomposition.zig",
}


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "triangle_union_area_vertical_decomposition"
            or workload.get("function_symbol") != "triangle_union_area_vertical_decomposition"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        raise ValueError("workload identity, ABI, or source attribution differs")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the references")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SOURCE_URL not in readme or "inclusion-exclusion" not in readme
            or "CC BY-SA 4.0" not in rights or "no upstream source code" not in rights):
        raise ValueError("README or rights note omits method/source boundary")
    if len(PORTS) != 10:
        raise ValueError("static inventory must enumerate ten language ports")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if (not source.is_file()
                or "triangle_union_area_vertical_decomposition" not in source.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"missing {language} implementation or README link: {relative}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload has no named fixtures")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture framing differs: {case['id']}")
        kwargs = dict(
            input_length=case.get("input_length"),
            input_is_null=case.get("input_is_null", False),
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
        )
        first = primary(values, **kwargs)
        second = independent(values, **kwargs)
        if first != second or first[0] != case.get("expected_result"):
            raise ValueError(f"references disagree with pinned result: {case['id']}")
        if first[1].hex() != case.get("expected_output_hex", "").lower():
            raise ValueError(f"pinned bytes differ from references: {case['id']}")
        if first[0] >= 0 and len(first[1]) != first[0]:
            raise ValueError(f"successful byte count differs: {case['id']}")
        if first[0] < 0 and first[1]:
            raise ValueError(f"error fixture must have no output: {case['id']}")
    required = {
        "unit-right-triangle", "identical-triangles", "contained-triangle-sharing-boundary",
        "overlap-with-rational-crossings", "shared-edge", "touch-at-one-vertex",
        "vertical-sides-and-reversed-winding", "degenerate-collinear-triangle",
        "short-output", "null-output", "malformed-precedes-capacity", "null-input",
    }
    if not required.issubset(seen):
        raise ValueError(f"workload omits required cases: {sorted(required-seen)}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
