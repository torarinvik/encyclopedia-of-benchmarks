"""Static reconciliation of bounded fixtures and both references; not run."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "k2_tree_compact_graph":
        issues.append("algorithm name mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    contract = workload.get("input", {})
    if contract.get("maximum_valid_words") != primary_oracle.MAX_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if contract.get("maximum_parseable_words") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if workload.get("output", {}).get("maximum_bytes") != primary_oracle.MAX_OUTPUT_BYTES:
        issues.append("maximum output length mismatch")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.MAX_WORKSPACE_BYTES:
        issues.append("workspace cap mismatch")

    cases = workload.get("cases", [])
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        input_length = case.get("input_length")
        if input_length is not None and input_length != len(values):
            issues.append(f"{case_id}: input_length differs from input_values")
            continue
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        args = (
            values,
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            input_length,
        )
        primary = primary_oracle.expected_output(*args)
        independent = independent_oracle.expected_output(*args)
        if primary != expected:
            issues.append(f"{case_id}: primary reference disagrees with fixture")
        if independent != expected:
            issues.append(f"{case_id}: independent reference disagrees with fixture")
        if primary != independent:
            issues.append(f"{case_id}: references disagree")
        if len(expected[1]) > primary_oracle.MAX_OUTPUT_BYTES:
            issues.append(f"{case_id}: output exceeds declared maximum")
    if not cases:
        issues.append("workload has no cases")
    maximum = next((case for case in cases if case.get("id") == "maximum_frame_and_output_empty_relation"), None)
    if maximum is None or len(maximum.get("input_values", [])) != 418 or maximum.get("expected_result") != 1032:
        issues.append("maximum frame/output fixture is missing or inconsistent")
    return issues


if __name__ == "__main__":
    errors = verify()
    if errors:
        raise SystemExit("\n".join(errors))
