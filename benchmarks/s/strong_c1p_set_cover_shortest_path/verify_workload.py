"""Static workload, link, and source inventory review for this package."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/strong_c1p_set_cover_shortest_path"
SYMBOL = "strong_c1p_set_cover_shortest_path"
SOURCE_URL = "https://num.math.uni-goettingen.de/bibi/preprintserie/preprints/schoebel/paper.pdf"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "overlapping-intervals-optimum",
    "disjoint-forced-columns",
    "nested-rows-reduced",
    "equal-start-and-ending-ties",
    "empty-column-ignored",
    "one-column-covers-every-row",
    "maximum-valid-strong-c1p-frame",
    "valid-uncoverable-zero-row",
    "invalid-nonconsecutive-row",
    "invalid-row-mask-high-bit",
    "invalid-zero-weight",
    "maximum-parseable-trailing-word",
    "short-output-capacity",
    "null-input",
    "null-output",
}


def validate_inventory(workload: Any) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
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
    if not all(isinstance(obj, dict) for obj in (source_spec, input_spec, output_spec)):
        return issues + ["workload is missing source/input/output objects"]
    if (
        workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or source_spec.get("url") != SOURCE_URL
        or input_spec.get("row_count_range") != [1, 8]
        or input_spec.get("column_count_range") != [1, 10]
        or input_spec.get("maximum_valid_length") != 20
        or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
        or output_spec.get("success_result") != 8
        or output_spec.get("invalid_input_result") != -1
        or output_spec.get("null_output_result") != -2
        or output_spec.get("insufficient_capacity_result") != -2
        or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
        or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"
    ):
        issues.append("workload identity, source, bounds, ABI, or error contract differs")

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
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        result = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (
            not isinstance(values, list)
            or type(length) is not int or length != len(values)
            or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
            or type(capacity) is not int or capacity < 0
            or type(result) is not int
            or type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null and (values or length != 0)
        ):
            issues.append(f"invalid workload fields: {case_id}")
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
            "input_length": length,
        }
        if primary(values, **kwargs) != (result, expected_bytes):
            issues.append(f"primary reference/fixture mismatch: {case_id}")
        if independent(values, **kwargs) != (result, expected_bytes):
            issues.append(f"independent reference/fixture mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))

    readme = PACKAGE / "README.md"
    if readme.is_file():
        contents = readme.read_text(encoding="utf-8")
        for language, extension in EXTENSIONS.items():
            target = f"../../../{language}/s/{SYMBOL}.{extension}"
            if f"]({target})" not in contents:
                issues.append(f"missing or incorrect README source link: {language}")
            elif not (PACKAGE / target).resolve().is_file():
                issues.append(f"README source link does not resolve: {language}")
        if SOURCE_URL not in contents:
            issues.append("README is missing the primary preprint URL")
    return issues


def review(workload: Any = None) -> None:
    """Raise ValueError when static inventory or fixture fields disagree."""
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ValueError(f"cannot read workload: {error}") from error
    issues = validate_inventory(workload)
    if issues:
        raise ValueError("\n".join(issues))


static_issues = validate_inventory
