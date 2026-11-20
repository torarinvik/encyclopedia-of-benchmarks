"""Optional source-only consistency review for pinned line-intersection cases."""

from __future__ import annotations

import json
from pathlib import Path

from independent_oracle import expected_output as independent_output
from primary_oracle import expected_output as primary_output


def workload_issues() -> list[str]:
    cases = json.loads(Path(__file__).with_name("workload.json").read_text(encoding="utf-8"))["cases"]
    issues: list[str] = []
    for case in cases:
        args = (
            case["input_values"], case.get("output_capacity"),
            case.get("input_is_null", False), case.get("output_is_null", False),
            case.get("input_length"),
        )
        expected = bytes.fromhex(case["expected_output_hex"])
        for label, oracle in (("primary", primary_output), ("independent", independent_output)):
            result, output = oracle(*args)
            if result != case["expected_result"] or output != expected:
                issues.append(f"{label} mismatch: {case['id']}")
    return issues
