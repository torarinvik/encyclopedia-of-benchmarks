"""Static package inventory and fixture/reference consistency checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_N, MAX_Q, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/o/online_bipartiteness_dsu"
SYMBOL = "online_bipartiteness_dsu"
EXTENSIONS = {"c":"c","c3":"c3","cpp":"cpp","elisa":"elisa","mojo":"mojo","nim":"nim","odin":"odin","rust":"rs","v":"v","zig":"zig"}
REQUIRED_CASES = {"empty-trace","odd-cycle","self-loop-and-disconnected","parallel-edge-is-consistent","bad-component-merge","maximum-query-batch","invalid-n","invalid-opcode","invalid-vertex","reserved-query-field","trailing-value","missing-header","null-input"}


def verify_workload(workload=None) -> list[str]:
    issues = []
    for filename in ("README.md","RIGHTS.md","INVENTORY.md","workload.json","primary_oracle.py","independent_oracle.py","verify_workload.py"):
        if not (PACKAGE / filename).is_file(): issues.append(f"missing package file: {filename}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "o" / f"{SYMBOL}.{extension}"
        if not path.is_file(): issues.append(f"missing source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"): issues.append(f"missing exported symbol: {language}")
    if workload is None:
        try: workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error: return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict): return issues + ["workload must be an object"]
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("n_range") != [1, MAX_N]
            or workload.get("input", {}).get("q_range") != [0, MAX_Q]
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload identity or bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list): return issues + ["missing cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case record"); continue
        case_id = case["id"]
        if case_id in seen: issues.append(f"duplicate case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        is_null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(is_null) is not bool or type(length) is not int
                or (is_null and (values or length != 0)) or (not is_null and length != len(values))
                or type(expected) is not int):
            issues.append(f"invalid case fields: {case_id}"); continue
        if primary(values, is_null, length) != expected or independent(values, is_null, length) != expected:
            issues.append(f"reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing: issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues
