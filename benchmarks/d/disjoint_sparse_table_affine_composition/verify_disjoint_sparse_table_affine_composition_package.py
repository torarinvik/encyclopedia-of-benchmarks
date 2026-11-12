"""Static inventory and fixture checker for the disjoint sparse table package."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output as primary_output
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "disjoint_sparse_table_affine_composition"
SOURCE_URLS = (
    "https://cp-algorithms.com/data_structures/sparse-table.html",
    "https://oiwiki.net/ds/cat-tree/",
)
PORTS = (
    "c/d/disjoint_sparse_table_affine_composition.c",
    "c3/d/disjoint_sparse_table_affine_composition.c3",
    "cpp/d/disjoint_sparse_table_affine_composition.cpp",
    "elisa/d/disjoint_sparse_table_affine_composition.elisa",
    "mojo/d/disjoint_sparse_table_affine_composition.mojo",
    "nim/d/disjoint_sparse_table_affine_composition.nim",
    "odin/d/disjoint_sparse_table_affine_composition.odin",
    "rust/d/disjoint_sparse_table_affine_composition.rs",
    "v/d/disjoint_sparse_table_affine_composition.v",
    "zig/d/disjoint_sparse_table_affine_composition.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES):
        raise ValueError("workload identity or bounds differ")
    sources = workload.get("source", {}).get("urls", [])
    if any(url not in sources for url in SOURCE_URLS):
        raise ValueError("workload source attribution is incomplete")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in seen:
            raise ValueError("fixture IDs must be unique strings")
        seen.add(case["id"])
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_output(case.get("input_values"), **options) != expected:
            raise ValueError(f"primary oracle/workload mismatch: {case['id']}")
        if independent_output(case.get("input_values"), **options) != expected:
            raise ValueError(f"independent oracle/workload mismatch: {case['id']}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if any(url not in readme or url not in rights for url in SOURCE_URLS):
        raise ValueError("README or rights note omits a source")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or SYMBOL not in path.read_text(encoding="utf-8"):
            raise ValueError(f"missing port or exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link {relative}")
    elisa = (ROOT / "elisa/d/disjoint_sparse_table_affine_composition.elisa").read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "mutable view[u8]" not in elisa:
        raise ValueError("Elisa must use safe views internally")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
