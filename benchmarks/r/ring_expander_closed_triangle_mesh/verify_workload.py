"""Static workload consistency helper; intentionally not executed here."""

from __future__ import annotations

import json
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPO = PACKAGE.parents[2]
sys.path.insert(0, str(REPO / "benchmarks"))

from ring_expander_closed_triangle_mesh_oracle import expected_output as primary_expected  # noqa: E402
from ring_expander_closed_triangle_mesh_verifier_oracle import expected_output as independent_expected  # noqa: E402


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return ["workload has no cases"]
    seen_ids: set[str] = set()
    for index, case in enumerate(cases):
        label = case.get("id", f"case[{index}]") if isinstance(case, dict) else f"case[{index}]"
        if not isinstance(case, dict):
            issues.append(f"{label}: case must be an object")
            continue
        if label in seen_ids:
            issues.append(f"{label}: duplicate case ID")
        seen_ids.add(label)
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        flags = {
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), case.get("expected_output_hex"))
        for oracle in (primary_expected, independent_expected):
            actual_result, actual_bytes = oracle(values, capacity=capacity, **flags)
            if actual_result != expected[0] or actual_bytes.hex() != expected[1]:
                issues.append(f"{label}: pinned output disagrees with an oracle")
                break
        if expected[0] >= 0 and expected[0] != len(expected[1]) // 2:
            issues.append(f"{label}: successful result differs from output byte count")
        if expected[0] < 0 and expected[1] != "":
            issues.append(f"{label}: error case must have an empty output")
    return issues


def verify_workload() -> list[str]:
    """Suite-facing workload verification entry point."""
    return workload_issues()
