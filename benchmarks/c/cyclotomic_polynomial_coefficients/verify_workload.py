"""Metadata-only comparison of workload fixtures with both references."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    workload: dict[str, Any] = json.loads((PACKAGE / "workload.json").read_text())
    errors: list[str] = []
    for case in workload["cases"]:
        expected_bytes = bytes.fromhex(case["expected_output_hex"])
        arguments = (
            case["input_values"],
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        for label, reference in (("primary", primary_oracle),
                                 ("independent", independent_oracle)):
            result, output = reference.expected_output(*arguments)
            if result != case["expected_result"] or output != expected_bytes:
                errors.append(f"{case['id']}: {label} reference disagrees with pinned result/bytes")
    return errors


if __name__ == "__main__":
    issues = verify_workload()
    for issue in issues:
        print(issue)
    raise SystemExit(bool(issues))
