"""Static inventory and fixture review for the virtual-tree package."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_VALID_INPUT_LENGTH,
        expected_output as primary_output,
    )
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_VALID_INPUT_LENGTH,
        expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "virtual_tree"
SOURCE_URL = "https://oiwiki.net/graph/virtual-tree/"
PORTS = (
    "c/v/virtual_tree.c",
    "c3/v/virtual_tree.c3",
    "cpp/v/virtual_tree.cpp",
    "elisa/v/virtual_tree.elisa",
    "mojo/v/virtual_tree.mojo",
    "nim/v/virtual_tree.nim",
    "odin/v/virtual_tree.odin",
    "rust/v/virtual_tree.rs",
    "v/v/virtual_tree.v",
    "zig/v/virtual_tree.zig",
)
PORT_VERTEX_LIMIT = {
    "c/v/virtual_tree.c": "#define VT_MAX_VIRTUAL 32",
    "c3/v/virtual_tree.c3": "const usz MAX_VIRTUAL = 32",
    "cpp/v/virtual_tree.cpp": "max_virtual = 32",
    "elisa/v/virtual_tree.elisa": "MAX_VIRTUAL: usize = 32",
    "mojo/v/virtual_tree.mojo": "MAX_VIRTUAL = 32",
    "nim/v/virtual_tree.nim": "MaxVirtual = 32",
    "odin/v/virtual_tree.odin": "MAX_VIRTUAL :: 32",
    "rust/v/virtual_tree.rs": "MAX_VIRTUAL: usize = 32",
    "v/v/virtual_tree.v": "max_virtual = 32",
    "zig/v/virtual_tree.zig": "MAX_VIRTUAL: usize = 32",
}


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_virtual_vertices") != 32
            or workload.get("output", {}).get("maximum_output_bytes") != MAX_OUTPUT_BYTES):
        raise ValueError("workload identity, provenance, or bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixture cases")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("each fixture needs a string ID")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        primary = primary_output(case.get("input_values"), **options)
        independent = independent_output(case.get("input_values"), **options)
        if primary != expected or independent != expected:
            raise ValueError(f"oracle/workload mismatch: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in rights:
        raise ValueError("provenance or clean-room rights note is missing")
    for relative in PORTS:
        port = ROOT / relative
        if not port.is_file():
            raise ValueError(f"missing port or exported symbol: {relative}")
        source = port.read_text(encoding="utf-8")
        if SYMBOL not in source:
            raise ValueError(f"missing port or exported symbol: {relative}")
        if PORT_VERTEX_LIMIT[relative] not in source:
            raise ValueError(f"port virtual-vertex bound differs from 32: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link {relative}")
    elisa = (ROOT / "elisa/v/virtual_tree.elisa").read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "mutable view[u8]" not in elisa:
        raise ValueError("Elisa must use safe views internally")
    if len(PORTS) != 10:
        raise ValueError("the package requires ten language ports")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
