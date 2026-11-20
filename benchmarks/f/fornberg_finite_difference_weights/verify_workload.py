"""Static reference/workload reconciliation API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_PARSEABLE,
        MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID,
        expected_output as independent_output,
    )
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output,
    )
except ImportError:
    from independent_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_PARSEABLE,
        MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID,
        expected_output as independent_output,
    )
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output,
    )

PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "fornberg_finite_difference_weights"
DOI_URL = "https://doi.org/10.1090/S0025-5718-1988-0935077-0"


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != DOI_URL):
        issues.append("workload identity, ABI, or source differs")
    inputs = workload.get("input", {})
    output = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (inputs.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or inputs.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or (INDEPENDENT_MAX_VALID, INDEPENDENT_MAX_PARSEABLE)
            != (MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH)
            or output.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workspace.get("bytes") != WORKSPACE_BYTES):
        issues.append("workload/reference input, output, or workspace bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"fixture input is not a list: {case_id}")
            continue
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        if type(input_is_null) is not bool or type(output_is_null) is not bool:
            issues.append(f"fixture null flags are not booleans: {case_id}")
            continue
        if type(length) is not int or type(capacity) is not int:
            issues.append(f"fixture length/capacity is missing: {case_id}")
            continue
        if ((input_is_null and (values or length != 0))
                or (not input_is_null and length != len(values))):
            issues.append(f"fixture input framing differs: {case_id}")
        if capacity < 0:
            issues.append(f"fixture capacity is negative: {case_id}")
        try:
            primary = expected_output(values, capacity, output_is_null, input_is_null, length)
            independent = independent_output(values, capacity, output_is_null,
                                             input_is_null, length)
        except (ArithmeticError, OverflowError, TypeError, ValueError, StopIteration) as error:
            issues.append(f"oracle could not classify {case_id}: {error}")
            continue
        pinned_result = case.get("expected_result")
        pinned_bytes = case.get("expected_output_hex")
        if primary != independent:
            issues.append(f"triangular and moment-system references disagree: {case_id}")
        if primary[0] != pinned_result:
            issues.append(f"fixture result differs from primary reference: {case_id}")
        if primary[1].hex() != pinned_bytes:
            issues.append(f"fixture bytes differ from primary reference: {case_id}")

    required = {
        "single-node-interpolation",
        "third-derivative-forward-four-node",
        "maximum-frame-and-output-node-hit",
        "maximum-output-one-byte-short",
        "maximum-parseable-trailing-word",
        "duplicate-nodes",
        "null-output",
        "malformed-before-output-capacity",
        "null-input",
    }
    missing = required - seen
    if missing:
        issues.append("required fixture categories missing: " + ", ".join(sorted(missing)))
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    return len(workload["cases"])


if __name__ == "__main__":
    print(f"{verify_workload()} fixtures reconciled")
