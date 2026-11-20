"""Static comparison of pinned fixtures with both package references."""

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle
    import primary_oracle


def workload_issues():
    issues = []
    workload = json.loads((Path(__file__).parent / "workload.json").read_text())
    for case in workload.get("cases", []):
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        is_null = case.get("input_is_null", False)
        out_null = case.get("output_is_null", False)
        expected_result = case.get("expected_result")
        expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        wanted = (expected_result, expected_bytes)
        if type(is_null) is not bool or type(out_null) is not bool:
            issues.append(f"{case.get('id')}: ABI null flags must be booleans")
        if is_null:
            if values != [] or input_length != 0:
                issues.append(f"{case.get('id')}: null-input framing must use an empty frame and length zero")
        elif not isinstance(values, list) or input_length != len(values):
            issues.append(f"{case.get('id')}: declared input length must match input_values")
        if type(capacity) is not int or capacity < 0:
            issues.append(f"{case.get('id')}: output capacity must be a nonnegative integer")
        if type(expected_result) is not int:
            issues.append(f"{case.get('id')}: expected result must be an integer")
        if type(expected_result) is int:
            if expected_result >= 0 and (expected_result != len(expected_bytes)
                    or (type(capacity) is int and expected_result > capacity)):
                issues.append(f"{case.get('id')}: successful result length and fixture capacity must match output bytes")
            if expected_result < 0 and expected_bytes:
                issues.append(f"{case.get('id')}: error cases must pin an empty output")
        for label, oracle in (("primary", primary_oracle), ("independent", independent_oracle)):
            got = oracle.expected_output(values, capacity, out_null, is_null, input_length)
            if got != wanted:
                issues.append(f"{case.get('id')}: {label} reference disagrees with pinned result/output")
    return issues


def verify_workload():
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
