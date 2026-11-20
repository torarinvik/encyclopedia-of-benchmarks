"""Static fixture, contract, README-link, and ten-port inventory review."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_N,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/l/lazy_segment_tree_range_add_max_right"
SYMBOL = "lazy_segment_tree_range_add_max_right"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "deferred-full-range-tag-followed-by-search", "overlapping-range-additions",
    "empty-suffix", "first-element-exceeds-limit", "entire-suffix-fits",
    "maximum-array-and-query-frame", "no-operations", "negative-initial-value",
    "negative-range-add-delta", "out-of-range-add-endpoint",
    "nonzero-query-reserved-field", "negative-query-limit", "unknown-operation",
    "truncated-operation-row", "trailing-input-word", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
        "independent_oracle.py", "verify_workload.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in EXTENSIONS.items():
            target = f"](../../../{language}/l/{SYMBOL}.{extension})"
            if target not in readme:
                issues.append(f"missing README source link: {language}")

    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "l" / f"{SYMBOL}.{extension}"
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

    input_spec = workload.get("input", {})
    contract = workload.get("contract", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or input_spec.get("n_range") != [1, MAX_N]
            or input_spec.get("operation_count_range") != [0, MAX_OPERATIONS]
            or input_spec.get("exact_length") != "2+n+4*q"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or contract.get("predicate") != "sum(values[left:end]) <= limit"
            or contract.get("range_action") != "add a nonnegative delta to every value in a half-open interval"):
        issues.append("workload identity, framing, bounds, or lazy max_right contract differs")

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
        if (primary(values, input_is_null=is_null, input_length=input_length) != expected
                or independent(values, input_is_null=is_null, input_length=input_length) != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
