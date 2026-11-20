"""Optional workload/reference consistency check; intentionally not executed."""

from __future__ import annotations

import json
from pathlib import Path

from independent_oracle import expected_output as independent_output
from primary_oracle import expected_output as primary_output


def workload_issues() -> list[str]:
    data = json.loads(Path(__file__).with_name("workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        status, output = primary_output(
            case["input_values"],
            case.get("output_capacity"),
            case.get("input_is_null", False),
            case.get("output_is_null", False),
            case.get("input_length"),
        )
        independent_status, independent_bytes = independent_output(
            case["input_values"],
            case.get("output_capacity"),
            case.get("input_is_null", False),
            case.get("output_is_null", False),
            case.get("input_length"),
        )
        expected_bytes = bytes.fromhex(case["expected_output_hex"])
        if status != case["expected_result"] or output != expected_bytes:
            issues.append(f"primary reference mismatch: {case['id']}")
        if independent_status != case["expected_result"] or independent_bytes != expected_bytes:
            issues.append(f"independent reference mismatch: {case['id']}")
    return issues
