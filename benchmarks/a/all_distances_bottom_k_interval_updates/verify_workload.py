"""Source-only workload/oracle reconciliation; this helper is intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES, expected_output as primary_expected,
    )
    from .independent_oracle import expected_output as independent_expected
except ImportError:
    from primary_oracle import (
        MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES, expected_output as primary_expected,
    )
    from independent_oracle import expected_output as independent_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "seeded-sketch-only", "out-of-order-multi-boundary-replacements",
    "dominated-arrival-no-update", "maximum-valid-frame-minimal-output",
    "maximum-output-capacity-short", "duplicate-rank-invalid",
    "seed-distances-not-increasing", "later-distance-not-after-seeds",
    "duplicate-distance-invalid", "trailing-word-invalid",
    "short-output-capacity", "null-output", "invalid-before-null-output",
    "null-input",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["cases must be an array"]
    issues: list[str] = []
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(ids) != len(set(ids)) or set(ids) != EXPECTED_IDS:
        issues.append("fixture IDs differ from the pinned case set")
    if (workload.get("algorithm") != "all_distances_bottom_k_interval_updates"
            or workload.get("function_symbol") != "all_distances_bottom_k_interval_updates"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_input_values")
                != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_values")
                != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload ABI/resource metadata differs from oracle constants")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("every fixture must be an object")
            continue
        values = case.get("input_values", [])
        input_length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(input_length) is not int
                or type(input_null) is not bool or type(output_null) is not bool
                or capacity is not None and type(capacity) is not int):
            issues.append(f"invalid ABI fields for {case.get('id')}")
            continue
        if input_null:
            if values or input_length != 0:
                issues.append(f"null input must have an empty zero-length frame: {case.get('id')}")
        elif input_length != len(values):
            issues.append(f"input length mismatch: {case.get('id')}")
        primary = primary_expected(values, capacity, output_null, input_null, input_length)
        independent = independent_expected(values, capacity, output_null, input_null,
                                            input_length)
        if primary != independent:
            issues.append(f"references disagree: {case.get('id')}")
        result, payload = primary
        if case.get("expected_result") != result:
            issues.append(f"pinned result mismatch: {case.get('id')}")
        expected_hex = case.get("expected_output_hex", "")
        if not isinstance(expected_hex, str) or expected_hex.lower() != payload.hex():
            issues.append(f"pinned output bytes mismatch: {case.get('id')}")
        if result < 0 and payload:
            issues.append(f"error result must not write output: {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if by_id.get("maximum-valid-frame-minimal-output", {}).get("input_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum frame fixture does not reach the valid input bound")
    if by_id.get("maximum-output-capacity-short", {}).get("output_capacity") != MAX_OUTPUT_BYTES - 1:
        issues.append("maximum-output capacity probe does not sit one byte below the cap")
    if by_id.get("maximum-output-capacity-short", {}).get("expected_result") != -2:
        issues.append("maximum-output capacity probe is missing")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        issues.append("null input fixture is missing")
    return issues


def static_issues() -> list[str]:
    return workload_issues()
