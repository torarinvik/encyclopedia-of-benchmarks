"""Static package and fixture checks for Chernick multiplier search."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_FACTOR,
    MAX_MULTIPLIER,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
    MIN_N,
    WORKSPACE_BYTES,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/c/chernick_carmichael_least_multiplier"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}
SYMBOL = "chernick_carmichael_least_multiplier"
EXPECTED = {3: 1, 4: 1, 5: 380, 6: 380, 7: 780_320, 8: 950_560, 9: 950_560}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "c" / f"{SYMBOL}.{extension}"
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
            or workload.get("source", {}).get("url") != "https://rosettagit.org/tasks/chernicks-carmichael-numbers/"
            or workload.get("input", {}).get("kind") != "signed_64_bit_integer_array"
            or workload.get("input", {}).get("encoding") != "[n]"
            or workload.get("input", {}).get("n_range") != [MIN_N, MAX_N]
            or workload.get("input", {}).get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("invalid_result") != -1
            or workload.get("output", {}).get("kind") != "signed_64_bit_integer"
            or workload.get("output", {}).get("result_range") != f"1..{MAX_MULTIPLIER}"
            or workload.get("output", {}).get("invalid_result") != -1
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or MAX_MULTIPLIER != 950_560
            or MAX_FACTOR != 1_095_045_121):
        issues.append("workload identity, search bounds, or workspace budget differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    results_by_n: dict[int, int] = {}
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(input_length) is not int
                or (input_is_null and (values or input_length != 0))
                or (not input_is_null and input_length != len(values))
                or type(expected) is not int):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        actual_primary = primary(values, input_is_null=input_is_null, input_length=input_length)
        actual_independent = independent(values, input_is_null=input_is_null, input_length=input_length)
        if actual_primary != expected or actual_independent != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")
        if len(values) == 1 and type(values[0]) is int and 3 <= values[0] <= 9:
            results_by_n[values[0]] = expected

    if results_by_n != EXPECTED:
        issues.append("the seven least-multiplier reference cases are incomplete or changed")
    required = {"below-domain", "above-domain", "trailing-value", "null-input"}
    if not required <= seen:
        issues.append("missing required cases: " + ", ".join(sorted(required - seen)))
    return issues


static_issues = verify_workload
