"""Static workload/reference reconciliation API; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        INVALID, MAX_PARSEABLE_INPUT, MAX_VALID_INPUT, NO_OUTPUT,
        OUTPUT_BYTES, WORKSPACE_BYTES, expected_output as primary_output,
    )
    from .independent_oracle import expected_output as independent_output
except ImportError:
    from primary_oracle import (
        INVALID, MAX_PARSEABLE_INPUT, MAX_VALID_INPUT, NO_OUTPUT,
        OUTPUT_BYTES, WORKSPACE_BYTES, expected_output as primary_output,
    )
    from independent_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "equal-weight-triangle-tie-rule", "heavier-chords-are-deleted",
    "equal-square-cycle-tie-order", "maximum-valid-frame-and-edge-count",
    "maximum-parseable-extra-word-rejected",
    "disconnected-nontarget-component-is-invalid",
    "deletion-that-isolates-nontarget-vertex-keeps-edge",
    "disconnected-components-rejected", "reversed-duplicate-undirected-pair-rejected",
    "self-loop-rejected", "weight-outside-domain-rejected",
    "edge-count-outside-domain-rejected", "trailing-word-rejected",
    "one-byte-short-output-capacity", "null-output-buffer",
    "malformed-input-before-output-capacity", "null-input",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Return static fixture mismatches without raising on a disagreement."""
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    errors: list[str] = []
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["cases must be a list"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or set(ids) != EXPECTED_IDS:
        errors.append("fixture IDs do not match the unique pinned fixture set")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "reverse_delete_mst"
            or workload.get("function_symbol") != "reverse_delete_mst"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT
            or workload.get("output", {}).get("maximum_bytes") != OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        errors.append("ABI or resource metadata differs from package constants")
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("every fixture must have an input_values array")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        output_capacity = case.get("output_capacity")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        if (type(length) is not int or type(output_capacity) is not int
                or type(input_null) is not bool or type(output_null) is not bool):
            errors.append(f"invalid ABI fields for {case.get('id')}")
            continue
        if input_null:
            if length != 0 or values:
                errors.append(f"null input frame is nonempty for {case.get('id')}")
        elif length != len(values):
            errors.append(f"input length mismatch for {case.get('id')}")
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            errors.append(f"invalid expected output for {case.get('id')}: {error}")
            continue
        for label, reference in (("primary", primary_output), ("independent", independent_output)):
            try:
                actual = reference(values, output_capacity, output_null, input_null, length)
            except Exception as error:
                errors.append(f"{label} oracle failed on {case.get('id')}: {error}")
                continue
            if actual != expected:
                errors.append(f"{label} reference disagrees for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum = by_id.get("maximum-valid-frame-and-edge-count", {})
    if (maximum.get("input_length") != MAX_VALID_INPUT
            or maximum.get("output_capacity") != OUTPUT_BYTES
            or maximum.get("expected_result") != OUTPUT_BYTES):
        errors.append("maximum frame/output fixture is absent or inconsistent")
    if by_id.get("maximum-parseable-extra-word-rejected", {}).get("input_length") != MAX_PARSEABLE_INPUT:
        errors.append("maximum parseable frame boundary is not pinned")
    if by_id.get("one-byte-short-output-capacity", {}).get("expected_result") != NO_OUTPUT:
        errors.append("short-capacity case is missing")
    if by_id.get("null-input", {}).get("input_is_null") is not True:
        errors.append("null-input ABI case is missing")
    if by_id.get("disconnected-nontarget-component-is-invalid", {}).get("expected_result") != INVALID:
        errors.append("disconnected-component case is missing")
    return errors
