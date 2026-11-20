"""Static fixture comparison for both Pagoda references."""

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle
    import primary_oracle


PACKAGE = Path(__file__).resolve().parent


def workload_issues():
    issues = []
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if workload.get("function_symbol") != "pagoda_meldable_priority_queue":
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        is_null = case.get("input_is_null", False)
        length = case.get("input_length")
        if type(is_null) is not bool:
            issues.append(f"{case_id}: input_is_null must be boolean")
            continue
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"{case_id}: missing list input or input_length")
            continue
        if not is_null and length != len(values):
            issues.append(f"{case_id}: non-null input length mismatch")
        expected = case.get("expected_result")
        first = primary_oracle.expected_output(values, is_null, length)
        second = independent_oracle.expected_output(values, is_null, length)
        if first != expected:
            issues.append(f"{case_id}: primary reference disagrees with pinned result")
        if second != expected:
            issues.append(f"{case_id}: independent reference disagrees with pinned result")
        if first != second:
            issues.append(f"{case_id}: references disagree")
    return issues


def verify_workload():
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
