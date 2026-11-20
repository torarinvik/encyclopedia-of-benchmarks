"""Static fixture/reference reconciliation; does not execute native ports."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
MAX_VALID = 312
MAX_PARSEABLE = 313
MAX_WORKSPACE = 16384


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI differs")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE):
        issues.append("input bounds differ")
    if workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE:
        issues.append("workspace bound differs")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases are missing"]
    required = {
        "triangle-mutual-selections",
        "two-cone-gap-selects-both-sides",
        "singleton-gap-equal-length-tie",
        "out-of-range-cone-invalid",
        "duplicate-dart-invalid",
        "trailing-word-invalid",
        "null-input-invalid",
    }
    observed = {case.get("id") for case in cases if isinstance(case, dict)}
    for missing in sorted(required - observed):
        issues.append(f"required case missing: {missing}")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload case is not an object")
            continue
        case_id = case.get("id", "<unknown>")
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or type(length) is not int or length != len(values):
            issues.append(f"input framing differs: {case_id}")
            continue
        if length > MAX_PARSEABLE:
            issues.append(f"input exceeds parseable limit: {case_id}")
            continue
        null_flag = case.get("input_is_null", False)
        if type(null_flag) is not bool:
            issues.append(f"input null flag is malformed: {case_id}")
            continue
        primary = primary_result(values, input_is_null=null_flag, input_length=length)
        independent = independent_result(values, input_is_null=null_flag, input_length=length)
        expected = case.get("expected_result")
        if primary != independent:
            issues.append(f"references disagree: {case_id}")
        if primary != expected:
            issues.append(f"pinned result differs: {case_id}")
    return issues
