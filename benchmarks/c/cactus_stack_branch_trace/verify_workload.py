"""Fixture framing and dual-reference checks; intentionally not executed here."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

try:
    from .primary_oracle import expected_output as primary
    from .independent_oracle import expected_output as independent
except ImportError:
    from primary_oracle import expected_output as primary
    from independent_oracle import expected_output as independent

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_LENGTH = 145
MAX_PARSEABLE_LENGTH = 146
MAX_OUTPUT = 768


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if (not isinstance(workload, dict)
            or workload.get("algorithm") != "cactus_stack_branch_trace"
            or workload.get("function_symbol") != "cactus_stack_branch_trace"
            or workload.get("abi") != "i64_array_bytes_output"):
        return ["workload identity mismatch"]
    spec = workload.get("input", {})
    if (spec.get("maximum_valid_length") != MAX_VALID_LENGTH
            or spec.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT
            or workload.get("workspace", {}).get("bytes") != 4096):
        return ["workload bounds mismatch"]

    issues: list[str] = []
    seen: set[str] = set()
    has_max_frame = has_max_output = has_short = has_notch = has_detach = False
    has_null_input = has_null_output = has_max_parseable = False
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return ["workload has no cases"]
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(length) is not int
                or type(input_null) is not bool or type(output_null) is not bool
                or type(capacity) is not int):
            issues.append(f"invalid framing/capacity metadata: {case_id}")
            continue
        if input_null:
            if values or length not in (0, MAX_PARSEABLE_LENGTH):
                issues.append(f"invalid null-input framing: {case_id}")
        elif length != len(values) or length > MAX_PARSEABLE_LENGTH:
            issues.append(f"input length mismatch: {case_id}")
        expected = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if type(expected) is not int or not isinstance(expected_hex, str):
            issues.append(f"missing expected result/payload: {case_id}")
            continue
        args = (values, capacity, output_null, input_null, length)
        primary_result = primary(*args)
        independent_result = independent(*args)
        if primary_result != independent_result:
            issues.append(f"references disagree: {case_id}")
        if primary_result != (expected, bytes.fromhex(expected_hex)):
            issues.append(f"fixture differs from references: {case_id}")
        has_max_frame |= not input_null and length == MAX_VALID_LENGTH
        has_max_parseable |= input_null and length == MAX_PARSEABLE_LENGTH or (
            not input_null and length == MAX_PARSEABLE_LENGTH)
        has_max_output |= expected == MAX_OUTPUT
        has_short |= expected == -2 and capacity == MAX_OUTPUT - 1
        has_notch |= case_id == "branch-notch-block-and-auto-detach"
        has_detach |= case_id in {"branch-notch-block-and-auto-detach", "empty-branch-immediately-detaches"}
        has_null_input |= input_null
        has_null_output |= output_null
    required = {
        "empty-trace", "branch-notch-block-and-auto-detach",
        "push-over-notch-pop-back-to-notch", "empty-branch-immediately-detaches",
        "maximum-valid-frame-and-output", "maximum-output-one-byte-short",
        "maximum-parseable-trailing-word", "null-input", "null-output",
    }
    if not required <= seen:
        issues.append("missing required cases: " + ", ".join(sorted(required - seen)))
    if not all((has_max_frame, has_max_parseable, has_max_output, has_short,
                has_notch, has_detach, has_null_input, has_null_output)):
        issues.append("workload misses a required boundary or branch behavior")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("; ".join(issues))
