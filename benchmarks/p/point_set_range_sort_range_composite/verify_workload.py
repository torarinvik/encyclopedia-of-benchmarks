"""Static fixture, oracle, and source inventory checks for the bounded package."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:  # Support direct invocation from this package directory.
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "point_set_range_sort_range_composite"
PORTS = {
    "c": ROOT / "c/p/point_set_range_sort_range_composite.c",
    "c3": ROOT / "c3/p/point_set_range_sort_range_composite.c3",
    "cpp": ROOT / "cpp/p/point_set_range_sort_range_composite.cpp",
    "elisa": ROOT / "elisa/p/point_set_range_sort_range_composite.elisa",
    "mojo": ROOT / "mojo/p/point_set_range_sort_range_composite.mojo",
    "nim": ROOT / "nim/p/point_set_range_sort_range_composite.nim",
    "odin": ROOT / "odin/p/point_set_range_sort_range_composite.odin",
    "rust": ROOT / "rust/p/point_set_range_sort_range_composite.rs",
    "v": ROOT / "v/p/point_set_range_sort_range_composite.v",
    "zig": ROOT / "zig/p/point_set_range_sort_range_composite.zig",
}
REQUIRED_CASES = {
    "official-sample-one",
    "official-sample-two-with-replacements",
    "ascending-and-descending-range-order",
    "point-replacement-before-composition",
    "non-query-sort-only-trace",
    "duplicate-initial-priority",
    "replacement-reuses-priority",
    "invalid-zero-affine-multiplier",
    "empty-sort-range-invalid",
    "truncated-variable-operation",
    "maximum-valid-frame-replacements-only",
    "null-input-pointer",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    if workload.get("algorithm") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        errors.append("algorithm or function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        errors.append("ABI mismatch")
    if workload.get("oracle") != "benchmarks/p/point_set_range_sort_range_composite/primary_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/p/point_set_range_sort_range_composite/independent_oracle.py":
        errors.append("independent oracle path mismatch")
    contract = workload.get("contract", {})
    if contract.get("array_length_range") != [1, 16] or contract.get("operation_count_range") != [1, 32]:
        errors.append("bounded N and Q limits mismatch")
    if contract.get("modulus") != 998244353 or workload.get("input", {}).get("maximum_valid_length") != 210:
        errors.append("modulus or packed-input bound mismatch")
    cases = workload.get("cases", [])
    identifiers = {case.get("id") for case in cases}
    if not REQUIRED_CASES <= identifiers:
        errors.append(f"missing fixtures: {sorted(REQUIRED_CASES - identifiers)}")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"fixture length mismatch: {case.get('id')}")
        null_input = case.get("input_is_null", False)
        if null_input and values:
            errors.append(f"null fixture contains values: {case.get('id')}")
        primary = primary_result(values, input_is_null=null_input, input_length=case.get("input_length"))
        independent = independent_result(values, input_is_null=null_input, input_length=case.get("input_length"))
        if primary != independent or case.get("expected_result") != primary:
            errors.append(f"oracle/fixture result mismatch: {case.get('id')}")
    source = workload.get("source", {})
    if source.get("url") != "https://judge.yosupo.jp/problem/point_set_range_sort_range_composite":
        errors.append("official task attribution missing")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            errors.append(f"function symbol missing: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
