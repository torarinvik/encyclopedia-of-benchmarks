"""Non-executed-during-drafting workload/reference agreement helper."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import expected_output as primary_expected
    from .independent_oracle import expected_output as independent_expected
except ImportError:
    from primary_oracle import expected_output as primary_expected
    from independent_oracle import expected_output as independent_expected

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [f"cannot read workload: {exc}"]
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or length != len(values):
            issues.append(f"{case_id}: input_length does not match input_values")
            continue
        capacity = case.get("output_capacity")
        for label, reference in (("primary", primary_expected), ("independent", independent_expected)):
            result, payload = reference(values, capacity=capacity, input_length=length)
            if result != case.get("expected_result"):
                issues.append(f"{case_id}: {label} result differs from pinned result")
            try:
                expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
            except ValueError:
                issues.append(f"{case_id}: malformed pinned output hex")
                continue
            if payload != expected_bytes:
                issues.append(f"{case_id}: {label} bytes differ from pinned output")
    return issues
