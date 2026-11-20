"""Package-local, non-executed fixture/reference consistency API."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle
    import primary_oracle


PACKAGE_DIR = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 256


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE_DIR / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload.json: {error}"]

    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI must be i64_array_bytes_output")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    workspace_meta = workload.get("workspace", {})
    if input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length differs from the oracle")
    if input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length differs from the oracle")
    if output_meta.get("maximum_output_bytes") != MAX_OUTPUT_BYTES:
        issues.append("maximum output size differs from the oracle")
    if workspace_meta.get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace cap differs from the oracle")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            issues.append(f"case has missing or duplicate id: {case_id!r}")
        else:
            seen.add(case_id)
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be a list")
            continue
        if type(input_length) is not int or input_length != len(values):
            issues.append(f"{case_id}: input_length must equal input_values length")
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"{case_id}: input exceeds parseable frame limit")
        if type(input_is_null) is not bool or type(output_is_null) is not bool:
            issues.append(f"{case_id}: null flags must be booleans")
        if type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES:
            issues.append(f"{case_id}: output_capacity is outside the bounded range")
        if type(case.get("expected_result")) is not int:
            issues.append(f"{case_id}: expected_result must be an integer")
            continue
        try:
            expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: expected_output_hex is malformed")
            continue
        pinned = (case["expected_result"], expected_bytes)
        for name, oracle in (("primary", primary_oracle), ("independent", independent_oracle)):
            actual = oracle.expected_output(
                values,
                output_capacity=capacity,
                output_is_null=output_is_null,
                input_is_null=input_is_null,
                input_length=input_length,
            )
            if actual != pinned:
                issues.append(f"{case_id}: {name} reference differs from pinned output")
        if pinned[0] >= 0 and len(expected_bytes) != pinned[0]:
            issues.append(f"{case_id}: success result differs from output byte count")
        if pinned[0] > MAX_OUTPUT_BYTES:
            issues.append(f"{case_id}: output exceeds the maximum byte bound")

    required_ids = {
        "empty-permutation", "maximum-rank-eight-symbols",
        "maximum-output-mixed-radix-zero", "maximum-output-capacity-short-by-one",
        "trailing-word-at-parseable-bound", "null-input", "null-output",
        "malformed-before-null-output",
    }
    missing = required_ids - seen
    if missing:
        issues.append("missing required boundary cases: " + ", ".join(sorted(missing)))
    return issues
