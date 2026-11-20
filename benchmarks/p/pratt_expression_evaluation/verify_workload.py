"""Static fixture comparison for the Pratt and shunting-yard references."""

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
    if workload.get("function_symbol") != "pratt_expression_evaluation":
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        if type(input_is_null) is not bool:
            issues.append(f"{case_id}: input_is_null must be boolean")
            continue
        if not isinstance(values, list) or type(input_length) is not int:
            issues.append(f"{case_id}: missing list input or input_length")
            continue
        if not input_is_null and input_length != len(values):
            issues.append(f"{case_id}: non-null input length mismatch")
        expected = case.get("expected_result")
        primary = primary_oracle.expected_result(values, input_is_null, input_length)
        independent = independent_oracle.expected_result(values, input_is_null, input_length)
        if primary != expected:
            issues.append(f"{case_id}: primary reference disagrees with pinned result")
        if independent != expected:
            issues.append(f"{case_id}: independent reference disagrees with pinned result")
        if primary != independent:
            issues.append(f"{case_id}: references disagree")
    return issues


def verify_workload():
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
