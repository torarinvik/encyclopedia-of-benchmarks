"""Static workload/reference and language-source inventory review."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_Q,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/fks_static_perfect_hash"
SYMBOL = "fks_static_perfect_hash"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "weighted-set-hits-and-misses", "three-key-shared-first-level-bucket",
    "empty-set", "zero-key-repeated-query", "maximum-key-and-query-count",
    "no-queries", "duplicate-stored-keys", "out-of-range-query",
    "truncated-frame", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "f" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in EXTENSIONS.items():
            link = f"../../../{language}/f/{SYMBOL}.{extension}"
            if f"]({link})" not in readme:
                issues.append(f"README omits or misroutes the {language} port link")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or input_spec.get("stored_key_count_range") != [0, MAX_N]
            or input_spec.get("query_count_range") != [0, MAX_Q]
            or input_spec.get("key_and_query_range") != [0, 255]
            or input_spec.get("exact_length") != "2 + stored_key_count + query_count"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or workload.get("output", {}).get("maximum_result") != 255
            or workload.get("output", {}).get("invalid_input_result") != -1
            or workload.get("contract", {}).get("prime") != 257
            or workload.get("contract", {}).get("table_rebuilt_each_call") is not True):
        issues.append("workload identity, frame bounds, or FKS profile differs")

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
        is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(is_null) is not bool
                or type(input_length) is not int
                or (is_null and (values or input_length != 0))
                or (not is_null and input_length != len(values))
                or type(expected) is not int):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        primary_result = primary(values, input_is_null=is_null, input_length=input_length)
        independent_result = independent(values, input_is_null=is_null, input_length=input_length)
        if primary_result != expected or independent_result != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
