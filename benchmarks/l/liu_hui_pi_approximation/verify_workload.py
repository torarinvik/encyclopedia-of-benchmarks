"""Optional workload/reference consistency check; intentionally not executed."""

from __future__ import annotations

import json
from pathlib import Path

from independent_oracle import expected_output as independent_output
from primary_oracle import expected_output as primary_output


def workload_issues() -> list[str]:
    path = Path(__file__).with_name("workload.json")
    data = json.loads(path.read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        expected = case["expected_result"]
        if (not isinstance(values, list)
                or type(input_is_null) is not bool
                or (input_is_null and (values or input_length != 1))
                or (not input_is_null and input_length != len(values))):
            issues.append(f"input framing mismatch: {case['id']}")
            continue
        value = values[0] if len(values) == 1 and not input_is_null else None
        primary = -1 if value is None else primary_output(value)
        independent = -1 if value is None else independent_output(value)
        if primary != expected:
            issues.append(f"primary reference mismatch: {case['id']}")
        if independent != expected:
            issues.append(f"independent reference mismatch: {case['id']}")
    return issues
