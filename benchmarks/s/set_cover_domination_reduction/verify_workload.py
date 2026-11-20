"""Static package inventory and oracle comparison for this benchmark."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/set_cover_domination_reduction"
SYMBOL = "set_cover_domination_reduction"
SOURCE_URL = "https://doi.org/10.1007/978-1-4939-2864-4_368"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-row-no-reduction",
    "row-dominance-then-column-dominance",
    "simple-column-dominance",
    "no-dominance-identities-retained",
    "advanced-column-domination",
    "infeasible-zero-row-preserved",
    "maximum-valid-frame-and-output",
    "invalid-row-mask-bits",
    "invalid-zero-weight",
    "invalid-trailing-word",
    "maximum-parseable-trailing-value",
    "short-output-capacity",
    "null-output",
    "null-input",
}


def validate_inventory(workload: Any) -> list[str]:
    """Return package-inventory and fixture issues without executing any port."""
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
        "independent_oracle.py", "verify_workload.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "s" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    source_spec = workload.get("source")
    input_spec = workload.get("input")
    output_spec = workload.get("output")
    if not isinstance(source_spec, dict) or not isinstance(input_spec, dict) or not isinstance(output_spec, dict):
        return issues + ["workload is missing source/input/output objects"]
    if (
        workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or source_spec.get("url") != SOURCE_URL
        or input_spec.get("row_count_range") != [1, 8]
        or input_spec.get("column_count_range") != [1, 8]
        or input_spec.get("maximum_valid_length") != 18
        or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
        or output_spec.get("invalid_input_result") != -1
        or output_spec.get("null_output_result") != -2
        or output_spec.get("insufficient_capacity_result") != -2
        or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
        or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"
    ):
        issues.append("workload identity, bounds, ABI, or error contract differs")

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
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        expected_result = case.get("expected_result")
        if (
            not isinstance(values, list)
            or type(input_length) is not int
            or type(input_is_null) is not bool
            or type(output_is_null) is not bool
            or type(capacity) is not int
            or type(expected_result) is not int
            or input_length != len(values)
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or capacity < 0
            or input_is_null and (values or input_length != 0)
        ):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        try:
            expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"invalid expected output bytes: {case_id}")
            continue
        kwargs = {
            "capacity": capacity,
            "output_is_null": output_is_null,
            "input_is_null": input_is_null,
            "input_length": input_length,
        }
        primary_result = primary(values, **kwargs)
        independent_result = independent(values, **kwargs)
        if primary_result != (expected_result, expected_bytes):
            issues.append(f"primary oracle/fixture mismatch: {case_id}")
        if independent_result != (expected_result, expected_bytes):
            issues.append(f"independent oracle/fixture mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))

    readme = PACKAGE / "README.md"
    if readme.is_file():
        text = readme.read_text(encoding="utf-8")
        for language, extension in EXTENSIONS.items():
            target = f"../../../{language}/s/{SYMBOL}.{extension}"
            if f"]({target})" not in text:
                issues.append(f"missing or incorrect README source link: {language}")
            elif not (PACKAGE / target).resolve().is_file():
                issues.append(f"README source link does not resolve: {language}")
        if SOURCE_URL not in text:
            issues.append("README is missing the chapter source link")
    return issues


def review(workload: Any = None) -> None:
    """Raise ValueError when the static package review reports any issues."""
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ValueError(f"cannot read workload: {error}") from error
    issues = validate_inventory(workload)
    if issues:
        raise ValueError("\n".join(issues))


static_issues = validate_inventory
