"""Static package and fixture consistency checker; do not infer timing claims."""
from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
from oracle import (  # noqa: E402
    MAX_VALID_INPUT, MAX_PARSEABLE_INPUT, MAX_OUTPUT_BYTES,
    MAX_WORKSPACE_BYTES, expected_output as primary,
)
from independent_oracle import expected_output as independent  # noqa: E402

PORTS = {
    "c": "c/m/measured_finger_tree_sequence.c",
    "c3": "c3/m/measured_finger_tree_sequence.c3",
    "cpp": "cpp/m/measured_finger_tree_sequence.cpp",
    "elisa": "elisa/m/measured_finger_tree_sequence.elisa",
    "mojo": "mojo/m/measured_finger_tree_sequence.mojo",
    "nim": "nim/m/measured_finger_tree_sequence.nim",
    "odin": "odin/m/measured_finger_tree_sequence.odin",
    "rust": "rust/m/measured_finger_tree_sequence.rs",
    "v": "v/m/measured_finger_tree_sequence.v",
    "zig": "zig/m/measured_finger_tree_sequence.zig",
}


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "measured_finger_tree_sequence"
            or workload.get("function_symbol") != "measured_finger_tree_sequence"
            or workload.get("abi") != "i64_array_bytes_output"):
        raise ValueError("package identity or ABI differs")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from oracle")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if ("persistent" not in readme.lower() or "Node2" not in readme
            or "measure" not in readme.lower() or "CC BY-SA 4.0" not in rights):
        raise ValueError("method or rights scope is missing")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if (not source.is_file()
                or "measured_finger_tree_sequence" not in source.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"missing {language} port/link: {relative}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("no workload cases")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in seen:
            raise ValueError("fixture IDs must be unique strings")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"bad framing in {case['id']}")
        kwargs = dict(input_length=case["input_length"],
                      input_is_null=case.get("input_is_null", False),
                      output_capacity=case.get("output_capacity"),
                      output_is_null=case.get("output_is_null", False))
        first = primary(values, **kwargs)
        second = independent(values, **kwargs)
        expected_words = case.get("expected_output_words", [])
        expected_bytes = b"".join(struct.pack("<q", word) for word in expected_words)
        if (first != second or first[0] != case.get("expected_result")
                or first[1] != expected_bytes):
            raise ValueError(f"oracle disagreement or pinned result mismatch: {case['id']}")
        if first[0] >= 0 and first[0] != len(expected_bytes):
            raise ValueError(f"byte count mismatch: {case['id']}")
        if first[0] < 0 and expected_bytes:
            raise ValueError(f"error fixture includes bytes: {case['id']}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} port paths")
