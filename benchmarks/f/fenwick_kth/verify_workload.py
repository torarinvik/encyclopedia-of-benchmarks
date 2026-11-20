"""Static fixture, source-inventory, and Markdown-link review for fenwick_kth."""

from __future__ import annotations

import json
from pathlib import Path
import re

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import MAX_INPUT_LENGTH, expected_output as primary_output
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import MAX_INPUT_LENGTH, expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "fenwick_kth"
PORTS = (
    "c/f/fenwick_kth.c", "c3/f/fenwick_kth.c3", "cpp/f/fenwick_kth.cpp",
    "elisa/f/fenwick_kth.elisa", "mojo/f/fenwick_kth.mojo", "nim/f/fenwick_kth.nim",
    "odin/f/fenwick_kth.odin", "rust/f/fenwick_kth.rs", "v/f/fenwick_kth.v",
    "zig/f/fenwick_kth.zig",
)
SOURCE_URLS = (
    "https://cp-algorithms.com/num_methods/binary_search.html#search-with-powers-of-2",
    "https://cp-algorithms.com/data_structures/fenwick.html",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH):
        raise ValueError("workload identity or bounds differ")
    if any(url not in workload.get("source", {}).get("urls", []) for url in SOURCE_URLS):
        raise ValueError("workload source attribution is incomplete")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixture cases")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in seen:
            raise ValueError("fixture IDs must be unique strings")
        seen.add(case["id"])
        options = {"input_is_null": case.get("input_is_null", False),
                   "input_length": case.get("input_length")}
        expected = case.get("expected_result")
        if primary_output(case.get("input_values"), **options) != expected:
            raise ValueError(f"primary oracle/workload mismatch: {case['id']}")
        if independent_output(case.get("input_values"), **options) != expected:
            raise ValueError(f"independent oracle/workload mismatch: {case['id']}")

    maximum = next((case for case in cases if case.get("id") == "maximum-valid-frame"), None)
    if (maximum is None or maximum.get("input_length") != 162
            or not isinstance(maximum.get("input_values"), list)
            or len(maximum["input_values"]) != 162
            or maximum.get("expected_result") != 33_792):
        raise ValueError("maximum frame must perform 32 rank-64 selections over 64 unit frequencies")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for url in SOURCE_URLS:
        if url not in readme or url not in rights:
            raise ValueError("README or RIGHTS omits a source")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            raise ValueError(f"missing port: {relative}")
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            raise ValueError(f"missing exported symbol in {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link {relative}")
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", readme):
        if "://" not in target and not (PACKAGE / target).resolve().is_file():
            raise ValueError(f"README target is missing: {target}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
