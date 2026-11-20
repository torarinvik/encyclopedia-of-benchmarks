"""Static metadata and independent-reference review for the BDD workload."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected as independent_expected
from .primary_oracle import expected as primary_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_CASE_IDS = {
    "empty-initial-set",
    "initial-state-only",
    "single-transition-reaches-state-one",
    "reachable-state-breaks-invariant",
    "initial-state-breaks-invariant",
    "existentially-quantified-input",
    "two-state-bits-no-transition",
    "empty-frame",
    "null-pointer",
    "trailing-word",
    "invalid-state-bit-count",
    "invalid-input-bit-count",
    "initial-mask-out-of-range",
    "invariant-mask-out-of-range",
    "non-boolean-relation-entry",
    "incomplete-relation-table",
    "i64-min-invalid",
    "i64-max-invalid",
    "maximum-valid-frame",
    "maximum-parseable-trailing-frame",
}
MAX_VALID_INPUT_LENGTH = 132
MAX_PARSEABLE_INPUT_LENGTH = 133
WORKSPACE_BYTES = 294_912


def verify_workload(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "bdd-symbolic-reachability-i64-array-scalar-v1"
            or workload.get("algorithm") != "bdd_symbolic_reachability"
            or workload.get("function_symbol") != "bdd_symbolic_reachability"
            or workload.get("abi") != "i64_array_scalar"
            or input_spec.get("n_range") != [1, 3]
            or input_spec.get("m_range") != [0, 1]
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or output_spec.get("valid_result_range") != [0, 511]
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or not isinstance(cases, list)
            or len(cases) != len(EXPECTED_CASE_IDS)
            or not all(isinstance(case, dict) for case in cases)
            or set(case_ids) != EXPECTED_CASE_IDS
            or len(case_ids) != len(EXPECTED_CASE_IDS)
            or len(case_ids) != len(set(case_ids))):
        return ["metadata, bounds, workspace, or fixture IDs differ from the reviewed contract"]

    issues: list[str] = []
    for case in cases:
        case_id = case["id"]
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list)
                or type(length) is not int
                or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(is_null) is not bool
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)):
            issues.append(f"invalid framed input: {case_id}")
            continue
        if is_null:
            if values or length != 0:
                issues.append(f"null-pointer fixture has non-null framing: {case_id}")
                continue
        elif length != len(values):
            issues.append(f"input_length does not frame input_values: {case_id}")
            continue
        primary = primary_expected(values)
        independent = independent_expected(values)
        if primary != independent:
            issues.append(f"ROBDD and explicit-state references disagree: {case_id}")
        if case.get("expected_result") != primary:
            issues.append(f"expected_result differs from both references: {case_id}")
        if primary != -1 and not 0 <= primary <= 511:
            issues.append(f"result is outside the encoded reachable-mask range: {case_id}")

    maximum = next((case for case in cases if case.get("id") == "maximum-valid-frame"), None)
    if maximum is None or maximum.get("input_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid truth-table frame is missing")
    trailing = next((case for case in cases
                     if case.get("id") == "maximum-parseable-trailing-frame"), None)
    if trailing is None or trailing.get("input_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable trailing-data frame is missing")
    null_case = next((case for case in cases if case.get("id") == "null-pointer"), None)
    if (null_case is None or null_case.get("input_is_null") is not True
            or null_case.get("input_length") != 0 or null_case.get("expected_result") != -1):
        issues.append("explicit null-pointer fixture is missing")
    return issues
