"""Static workload/reference reconciliation API; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_WORKSPACE_BYTES,
        expected_output as primary_output,
    )
    from .independent_oracle import expected_output as independent_output
except ImportError:
    from primary_oracle import (
        MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_WORKSPACE_BYTES,
        expected_output as primary_output,
    )
    from independent_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_OUTPUT_BYTES = MAX_N + 1
EXPECTED_IDS = {
    "empty-sequence", "single-negative-survivor", "same-direction-survivors",
    "diverging-directions-do-not-collide", "equal-magnitudes-annihilate",
    "positive-survivor-is-larger", "incoming-negative-is-larger",
    "cascade-removes-multiple-left-survivors", "maximum-valid-frame-and-output",
    "maximum-output-one-byte-short", "maximum-parseable-trailing-word",
    "zero-size-invalid-before-capacity", "size-outside-signed-byte-domain",
    "count-above-bound", "trailing-word-invalid", "null-output", "null-input",
    "declared-length-mismatch",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Return pinned fixture mismatches without raising or executing native code."""
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
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "asteroid_collision_stack"
            or workload.get("function_symbol") != "asteroid_collision_stack"
            or workload.get("abi") != "i64_array_bytes_output"
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workspace.get("bytes") != MAX_WORKSPACE_BYTES):
        errors.append("ABI or resource metadata differs from package constants")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return errors + ["cases must be a list"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or set(ids) != EXPECTED_IDS:
        errors.append("fixture IDs do not match the pinned fixture set")
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("every fixture must provide input_values")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        if (type(length) is not int or type(capacity) is not int
                or type(input_null) is not bool or type(output_null) is not bool):
            errors.append(f"invalid ABI framing for {case.get('id')}")
            continue
        if input_null:
            if values or length != 0:
                errors.append(f"null input must have an empty zero-length frame: {case.get('id')}")
        elif length != len(values):
            if (case.get("id") != "declared-length-mismatch"
                    or length != 0 or values != [0]):
                errors.append(f"declared input length differs from values: {case.get('id')}")
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            errors.append(f"invalid expected output for {case.get('id')}: {error}")
            continue
        for label, reference in (("primary", primary_output), ("independent", independent_output)):
            try:
                actual = reference(values, capacity, output_null, input_null, length)
            except Exception as error:
                errors.append(f"{label} reference failed on {case.get('id')}: {error}")
                continue
            if actual != expected:
                errors.append(f"{label} reference disagrees for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum = by_id.get("maximum-valid-frame-and-output", {})
    if (maximum.get("input_length") != MAX_VALID_INPUT_LENGTH
            or maximum.get("output_capacity") != MAX_OUTPUT_BYTES
            or maximum.get("expected_result") != MAX_OUTPUT_BYTES):
        errors.append("maximum valid input/output fixture is absent or inconsistent")
    if by_id.get("maximum-parseable-trailing-word", {}).get("input_length") != MAX_PARSEABLE_INPUT_LENGTH:
        errors.append("maximum parseable input frame is not pinned")
    if by_id.get("maximum-output-one-byte-short", {}).get("expected_result") != -2:
        errors.append("maximum-output one-byte-short case is missing")
    precedence = by_id.get("zero-size-invalid-before-capacity", {})
    if precedence.get("expected_result") != -1 or precedence.get("output_capacity") != 0:
        errors.append("malformed-before-capacity behavior is not pinned")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        errors.append("null-input ABI path is missing")
    if by_id.get("null-output", {}).get("output_is_null") is not True:
        errors.append("null-output ABI path is missing")
    if by_id.get("count-above-bound", {}).get("expected_result") != -1:
        errors.append("out-of-range item-count case is missing")
    return errors


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
