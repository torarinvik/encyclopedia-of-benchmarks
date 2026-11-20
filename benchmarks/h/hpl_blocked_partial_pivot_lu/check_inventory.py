"""Static metadata and reference-fixture checks; never invokes a native port."""

from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Any

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    ABSOLUTE_TOLERANCE,
    MAX_OUTPUT_BYTES,
    MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    RELATIVE_TOLERANCE,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "hpl_blocked_partial_pivot_lu"
SOURCE_URL = "https://netlib.sandia.gov/benchmark/hpl/algorithm.html"
PORTS = {
    "c": "c/h/hpl_blocked_partial_pivot_lu.c",
    "c3": "c3/h/hpl_blocked_partial_pivot_lu.c3",
    "cpp": "cpp/h/hpl_blocked_partial_pivot_lu.cpp",
    "elisa": "elisa/h/hpl_blocked_partial_pivot_lu.elisa",
    "mojo": "mojo/h/hpl_blocked_partial_pivot_lu.mojo",
    "nim": "nim/h/hpl_blocked_partial_pivot_lu.nim",
    "odin": "odin/h/hpl_blocked_partial_pivot_lu.odin",
    "rust": "rust/h/hpl_blocked_partial_pivot_lu.rs",
    "v": "v/h/hpl_blocked_partial_pivot_lu.v",
    "zig": "zig/h/hpl_blocked_partial_pivot_lu.zig",
}
REQUIRED_CASES = {
    "two_by_two_no_pivot_swap",
    "two_by_two_pivot_swap",
    "equal_magnitude_tie_keeps_lowest_row",
    "panel_second_column_swap",
    "maximum_dimension_diagonal",
    "singular_after_row_pivot",
    "fractional_matrix_entry",
    "fractional_dimension",
    "truncated_matrix",
    "matrix_entry_out_of_range",
    "extra_parseable_word",
    "maximum_parseable_length_trailing_word",
    "null_input",
    "invalid_input_precedes_null_output",
    "valid_input_null_output",
    "valid_input_short_output",
}


def _same_output(left: list[float], right: list[float]) -> bool:
    return len(left) == len(right) and all(
        math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE, abs_tol=ABSOLUTE_TOLERANCE)
        for a, b in zip(left, right)
    )


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    expected_measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 100,
    }
    source = inventory.get("source", {})
    contract = inventory.get("contract", {})
    if (inventory.get("algorithm") != SYMBOL or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "float64_slice_io" or source.get("url") != SOURCE_URL
            or contract.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or contract.get("maximum_output_elements") != MAX_OUTPUT_ELEMENTS
            or contract.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or contract.get("workspace_bytes") != WORKSPACE_BYTES
            or contract.get("measurement") != expected_measurement):
        issues.append("inventory identity, provenance, or bounds differ")

    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL or workload.get("abi") != "float64_slice_io"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "float64_slice_io_call"
            or {key: workload.get("measurement", {}).get(key) for key in
                ("sample_count", "warmup_rounds", "repetitions_per_sample")} != {
                    key: expected_measurement[key] for key in
                    ("sample_count", "warmup_rounds", "repetitions_per_sample")}):
        issues.append("workload identity, provenance, measurement, or bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be an array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected_result = case.get("expected_result")
        expected_values = case.get("expected_output")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected_result) is not int or not isinstance(expected_values, list)
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or (capacity is not None and (type(capacity) is not int or capacity < 0))):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if length > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input bound: {case_id}")
        kwargs = {
            "input_length": length,
            "input_is_null": input_is_null,
            "output_is_null": output_is_null,
            "output_capacity": capacity,
        }
        data = None if input_is_null else values
        primary_result, primary_values = primary_output(data, **kwargs)
        independent_result, independent_values = independent_output(data, **kwargs)
        if primary_result != independent_result or primary_result != expected_result:
            issues.append(f"fixture/reference result mismatch: {case_id}")
        if not _same_output(primary_values, independent_values):
            issues.append(f"independent references disagree: {case_id}")
        if not _same_output(primary_values, expected_values):
            issues.append(f"fixture output differs from references: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))
    max_case = next((case for case in cases if isinstance(case, dict)
                     and case.get("id") == "maximum_dimension_diagonal"), None)
    if (max_case is None or max_case.get("input_length") != MAX_VALID_INPUT_LENGTH
            or max_case.get("expected_result") != MAX_OUTPUT_ELEMENTS):
        issues.append("maximum fixture must cover 65 input values and 72 output values")

    readme_normalized = " ".join(readme.split()).lower()
    for phrase in (SOURCE_URL, "right-looking", "partial pivoting", "block width at two",
                   "zero maximum pivot", "mpi", "linpack_lu_solve", "blocked_lu_factorization"):
        if phrase.lower() not in readme_normalized:
            issues.append(f"README omits profile/source distinction: {phrase}")
    if SOURCE_URL not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")

    languages = inventory.get("languages", {})
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} ABI symbol: {relative}")
        if languages.get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} port path")
    for name in ("README.md", "RIGHTS.md", "workload.json", "INVENTORY.json",
                 "primary_oracle.py", "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
