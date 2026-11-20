"""Callable static fixture/reference reconciliation; not run during authoring."""
from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as independent,
)
from .primary_oracle import expected_output as primary

PACKAGE = Path(__file__).resolve().parent
NAME = "signed_permutation_overlap_forest_components"
REQUIRED_CASES = {
    "identity-single-gene", "negative-single-gene",
    "overlapping-cycle-extents-merge", "maximum-identity-cycle-output",
    "duplicate-absolute-gene", "zero-gene", "out-of-range-gene",
    "trailing-input-word", "signed-int64-minimum-is-invalid",
    "short-output-capacity", "null-input", "null-output",
}


def workload_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    workspace = workload.get("workspace")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[n,signed_gene_0,...,signed_gene_(n-1)]"
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("encoding") != "[cycle_count,(cycle_begin,cycle_end,component_root)*cycle_count]"
            or not isinstance(workspace, dict)
            or workspace.get("bytes") != WORKSPACE_BYTES):
        return ["identity, ABI, bounds, or workspace metadata mismatch"]

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return ["fixture cases are missing"]
    issues: list[str] = []
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or capacity < 0
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or (input_is_null and values)
                or (not input_is_null and length != len(values))):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case_id}")
            continue
        args = (values, capacity, output_is_null, input_is_null, length)
        if (type(expected[0]) is not int or primary(*args) != expected
                or independent(*args) != expected):
            issues.append(f"oracle/fixture disagreement: {case_id}")
            continue
        if expected[0] >= 0 and (expected[0] != len(expected[1])
                                 or expected[0] > MAX_OUTPUT_BYTES
                                 or expected[0] % 8 != 0):
            issues.append(f"successful output length mismatch: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    raise SystemExit(0)
