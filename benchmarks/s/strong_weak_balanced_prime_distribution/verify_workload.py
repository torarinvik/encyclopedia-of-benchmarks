"""Static checks for fixture identity, frame bounds, and oracle agreement."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent
EXPECTED_CASES = {
    "first-prime-weak",
    "first-balanced-prime-included",
    "mixed-through-eleven",
    "all-classes-through-one-hundred",
    "sequence-cross-check-through-one-thousand",
    "maximum-bound-source-cross-check",
    "limit-below-domain",
    "limit-above-domain",
    "zero-limit",
    "negative-limit",
    "wrong-empty-frame",
    "trailing-word",
    "null-input-zero-length",
    "null-input-maximum-parseable-length",
}


def verify() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "strong_weak_balanced_prime_distribution"
            or workload.get("function_symbol") != "strong_weak_balanced_prime_distribution"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    spec = workload.get("input", {})
    if (spec.get("valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or spec.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or spec.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or spec.get("inclusive_limit_range") != [primary_oracle.MIN_LIMIT, primary_oracle.MAX_LIMIT]
            or spec.get("invalid_result") != primary_oracle.INVALID_RESULT):
        issues.append("workload input bounds differ from the primary contract")
    output = workload.get("output", {})
    if (output.get("kind") != "signed_i64_scalar"
            or output.get("field_base") != primary_oracle.FIELD_BASE):
        issues.append("output kind or packing base mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    case_ids = [case.get("id") for case in cases]
    if len(case_ids) != len(set(case_ids)) or set(case_ids) != EXPECTED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length", len(values)) != len(values):
            issues.append(f"frame length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length", len(values)),
        }
        expected = case.get("expected_result")
        if primary_oracle.expected_result(values, **arguments) != expected:
            issues.append(f"primary fixture mismatch: {case_id}")
        if independent_oracle.expected_result(values, **arguments) != expected:
            issues.append(f"independent fixture mismatch: {case_id}")
    return issues
