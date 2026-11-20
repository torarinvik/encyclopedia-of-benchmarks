"""Static workload/reference reconciliation API; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_output as primary_output,
    )
    from .independent_oracle import expected_output as independent_output
except ImportError:
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_output as primary_output,
    )
    from independent_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "order-zero-base-curve", "order-one-recursive-curve",
    "maximum-order-and-output", "maximum-output-one-byte-short",
    "maximum-parseable-extra-word", "negative-order", "order-above-bound",
    "empty-nonnull-frame", "null-input", "null-output",
    "malformed-before-capacity",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Report fixture or metadata disagreements without native execution."""
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    errors: list[str] = []
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (
        workload.get("schema_version") != 1
        or workload.get("algorithm") != "sierpinski_curve_trace"
        or workload.get("function_symbol") != "sierpinski_curve_trace"
        or workload.get("abi") != "i64_array_bytes_output"
        or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
        or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
        or workspace.get("bytes") != MAX_WORKSPACE_BYTES
    ):
        errors.append("ABI or resource metadata differs from package constants")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return errors + ["cases must be a list"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or set(ids) != EXPECTED_IDS:
        errors.append("fixture IDs differ from the pinned workload set")
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("every case must contain input_values")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        if (
            type(length) is not int
            or type(capacity) is not int
            or type(input_null) is not bool
            or type(output_null) is not bool
        ):
            errors.append(f"invalid ABI framing for {case.get('id')}")
            continue
        if length != len(values):
            errors.append(f"input length differs from value buffer for {case.get('id')}")
        if input_null and (values or length != 0):
            errors.append(f"null input frame is not empty for {case.get('id')}")
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            errors.append(f"invalid expected output for {case.get('id')}: {error}")
            continue
        for label, reference in (("primary", primary_output), ("independent", independent_output)):
            try:
                actual = reference(values, capacity, output_null, input_null, length)
            except Exception as error:
                errors.append(f"{label} reference failed for {case.get('id')}: {error}")
                continue
            if actual != expected:
                errors.append(f"{label} reference differs for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if (
        by_id.get("maximum-order-and-output", {}).get("expected_result") != MAX_OUTPUT_BYTES
        or by_id.get("maximum-order-and-output", {}).get("output_capacity") != MAX_OUTPUT_BYTES
    ):
        errors.append("maximum output success fixture is missing")
    if by_id.get("maximum-output-one-byte-short", {}).get("expected_result") != -2:
        errors.append("one-byte-short capacity fixture is missing")
    if by_id.get("maximum-parseable-extra-word", {}).get("input_length") != MAX_PARSEABLE_INPUT_LENGTH:
        errors.append("maximum parseable input boundary is missing")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        errors.append("null-input ABI case is missing")
    if by_id.get("null-output", {}).get("output_is_null") is not True:
        errors.append("null-output ABI case is missing")
    return errors


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
