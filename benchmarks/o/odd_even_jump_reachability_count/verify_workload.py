"""Static fixture/reference consistency API; intentionally not executed here."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import INVALID, MAX_N, expected as primary_expected
    from .independent_oracle import expected as independent_expected
except ImportError:
    from primary_oracle import INVALID, MAX_N, expected as primary_expected
    from independent_oracle import expected as independent_expected

PACKAGE = Path(__file__).resolve().parent


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["cases must be a list"]
    errors: list[str] = []
    expected_ids = {
        "one-item", "no-odd-successor-at-first", "equal-value-earliest-target",
        "strictly-descending", "alternating-duplicate-values", "mixed-transition-chain",
        "mixed-negative-values", "maximum-equal-array", "empty-frame", "null-pointer",
        "zero-count", "wrong-count", "trailing-word", "value-above-bound", "value-below-bound",
    }
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids):
        errors.append("case records must be objects with unique ids")
    if set(ids) != expected_ids:
        errors.append("fixture identifiers differ from the pinned workload")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "odd_even_jump_reachability_count"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_input_words") != MAX_N + 1
            or workload.get("input", {}).get("maximum_parseable_input_words") != MAX_N + 2
            or workload.get("workspace", {}).get("bytes") != 4096):
        errors.append("workload metadata differs from the bounded contract")
    complexity = workload.get("complexity", {})
    complexity_fields = (
        ("primary_time", "O(n^2)"),
        ("primary_auxiliary_space", "O(n)"),
        ("independent_reference_time", "O(n^2)"),
        ("independent_reference_auxiliary_space", "O(n)"),
    )
    if not isinstance(complexity, dict) or any(
        not isinstance(complexity.get(field), str)
        or not complexity[field].startswith(prefix)
        for field, prefix in complexity_fields
    ):
        errors.append("workload complexity metadata is missing or inconsistent")
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append("each fixture must contain an input_values array")
            continue
        values = case["input_values"]
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if type(input_length) is not int or input_length < 0 or type(input_is_null) is not bool:
            errors.append(f"invalid ABI framing for {case.get('id')}")
            continue
        if not input_is_null and input_length != len(values):
            errors.append(f"input_length does not match values for {case.get('id')}")
            continue
        if input_is_null and (input_length != 0 or values):
            errors.append(f"null frame must have no values and zero length for {case.get('id')}")
            continue
        primary = primary_expected(values, input_is_null, input_length)
        independent = independent_expected(values, input_is_null, input_length)
        if primary != independent:
            errors.append(f"references disagree for {case.get('id')}")
        if case.get("expected_result") != primary:
            errors.append(f"expected_result differs for {case.get('id')}")
        if primary != INVALID and not 1 <= primary <= MAX_N:
            errors.append(f"result is out of bounds for {case.get('id')}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum = by_id.get("maximum-equal-array", {})
    if maximum.get("input_length") != MAX_N + 1 or maximum.get("expected_result") != MAX_N:
        errors.append("maximum-size fixture does not pin the maximum valid frame/result")
    null_case = by_id.get("null-pointer", {})
    if null_case.get("input_is_null") is not True or null_case.get("input_length") != 0:
        errors.append("null-pointer fixture does not pin the null ABI case")
    return errors
