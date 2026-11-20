"""Static inventory and fixture checks for the perfect-shuffle order profile."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/p/perfect_shuffle_order"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}
SYMBOL = "perfect_shuffle_order"


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "p" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_input_length") != 1
            or workload.get("input", {}).get("maximum_parseable_input_length") != 2
            or workload.get("workspace", {}).get("bytes") != 196608
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload identity, ABI limits, or workspace budget differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        if (not isinstance(values, list) or type(expected) is not int
                or type(input_is_null) is not bool or type(input_length) is not int
                or (input_is_null and (values or input_length != 0))
                or (not input_is_null and input_length != len(values))
                or primary(values, input_is_null=input_is_null, input_length=input_length) != expected
                or independent(values, input_is_null=input_is_null, input_length=input_length) != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    required = {"two-card-deck", "eight-card-deck", "fifty-two-card-deck",
                "1020-card-deck", "maximum-deck", "odd-deck", "null-input"}
    if not required <= seen:
        issues.append("missing required cases: " + ", ".join(sorted(required - seen)))
    return issues


static_issues = verify_workload
