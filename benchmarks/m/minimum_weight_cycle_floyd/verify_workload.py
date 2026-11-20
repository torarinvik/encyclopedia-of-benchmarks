"""Static workload/reference reconciliation for minimum_weight_cycle_floyd."""

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
    from .check_inventory import static_issues
except ImportError:
    import independent_oracle
    import primary_oracle
    from check_inventory import static_issues

PACKAGE = Path(__file__).resolve().parent


def workload_issues():
    issues = list(static_issues())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    for case in workload.get("cases", []):
        expected_hex = case.get("expected_output_hex", "")
        try:
            expected_payload = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"{case.get('id')}: invalid expected hex")
            continue
        args = (
            case.get("input_values"), case.get("output_capacity"),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case.get("input_length"),
        )
        primary = primary_oracle.expected_output(
            args[0], output_capacity=args[1], output_is_null=args[2],
            input_is_null=args[3], input_length=args[4])
        independent = independent_oracle.expected_output(
            args[0], output_capacity=args[1], output_is_null=args[2],
            input_is_null=args[3], input_length=args[4])
        expected = (case.get("expected_result"), expected_payload)
        if primary != expected:
            issues.append(f"{case.get('id')}: primary reference differs from fixture")
        if independent != expected:
            issues.append(f"{case.get('id')}: independent reference differs from fixture")
        if primary != independent:
            issues.append(f"{case.get('id')}: references disagree")
    return issues
