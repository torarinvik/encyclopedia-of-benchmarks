"""Static workload/reference reconciliation for next_palindromic_number."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import (
        INVALID, MAX_INPUT, MAX_PARSEABLE_INPUT_LENGTH,
        expected as primary_expected,
    )
    from .independent_oracle import expected as independent_expected
except ImportError:
    from primary_oracle import (
        INVALID, MAX_INPUT, MAX_PARSEABLE_INPUT_LENGTH,
        expected as primary_expected,
    )
    from independent_oracle import expected as independent_expected

PACKAGE = Path(__file__).resolve().parent
EXPECTED_CASE_IDS = {
    "zero", "single-digit-middle", "single-digit-carry", "two-digit-leading-boundary",
    "already-palindromic", "same-length-prefix-carry", "all-nines-four-digits",
    "maximum-input", "negative-input", "above-bound", "empty-frame", "null-pointer",
    "trailing-word",
}


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["workload cases must be a list"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "next_palindromic_number"
            or workload.get("function_symbol") != "next_palindromic_number"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_input_words") != 1
            or workload.get("input", {}).get("maximum_parseable_input_words") != 2
            or workload.get("output", {}).get("maximum_result") != 10000000000000001
            or set(ids) != EXPECTED_CASE_IDS or len(ids) != len(EXPECTED_CASE_IDS)):
        errors.append("metadata or fixture IDs differ from the bounded contract")
        return errors
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("each case must contain an input_values array")
            continue
        values = case["input_values"]
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (type(input_length) is not int or input_length < 0
                or input_length > MAX_PARSEABLE_INPUT_LENGTH
                or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
            errors.append(f"invalid input_length for {case.get('id')}")
            continue
        if type(input_is_null) is not bool:
            errors.append(f"invalid input_is_null for {case.get('id')}")
            continue
        if not input_is_null and input_length != len(values):
            errors.append(f"input_length does not frame values for {case.get('id')}")
            continue
        if input_is_null and input_length != 0:
            errors.append(f"null-pointer case must have zero input_length for {case.get('id')}")
            continue
        if input_is_null and values:
            errors.append(f"null-pointer case must not carry input values for {case.get('id')}")
            continue
        primary = primary_expected(values, input_is_null, input_length)
        independent = independent_expected(values, input_is_null, input_length)
        if primary != independent:
            errors.append(f"references disagree for {case.get('id')}")
        if case.get("expected_result") != primary:
            errors.append(f"pinned result differs for {case.get('id')}")
        if primary >= 0 and (primary <= values[0] or primary > 10000000000000001):
            errors.append(f"result violates strict successor bounds for {case.get('id')}")
    maximum = next((case for case in cases if case.get("id") == "maximum-input"), None)
    if (maximum is None or maximum.get("input_values") != [MAX_INPUT]
            or maximum.get("expected_result") != 10000000000000001):
        errors.append("maximum-width carry case is missing")
    null_case = next((case for case in cases if case.get("id") == "null-pointer"), None)
    if (null_case is None or null_case.get("input_is_null") is not True
            or null_case.get("input_length") != 0 or null_case.get("input_values") != []
            or null_case.get("expected_result") != INVALID):
        errors.append("explicit null-pointer ABI case is missing")
    return errors


def main() -> int:
    errors = workload_issues()
    if errors:
        raise SystemExit("\n".join(errors))
    return 0
