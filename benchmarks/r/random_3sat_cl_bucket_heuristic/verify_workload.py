"""Source-level fixture reconciler for the two CL references; not run here."""

from __future__ import annotations

import json
from pathlib import Path

from benchmarks.r.random_3sat_cl_bucket_heuristic.independent_oracle import expected_output as independent_output
from benchmarks.r.random_3sat_cl_bucket_heuristic.primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ["workload.json is unreadable or invalid JSON"]
    issues: list[str] = []
    for case in workload.get("cases", []):
        label = case.get("id", "<unnamed>")
        values = case.get("input_values")
        input_length = case.get("input_length")
        if not isinstance(values, list) or input_length != len(values):
            if not case.get("input_is_null"):
                issues.append(f"{label}: input framing does not match the value vector")
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": input_length,
        }
        primary = primary_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        if primary != independent:
            issues.append(f"{label}: primary and independent references disagree")
        expected_result = case.get("expected_result")
        if primary[0] != expected_result:
            issues.append(f"{label}: expected_result differs from both references")
        expected_hex = case.get("expected_output_hex")
        if expected_hex is not None and primary[1].hex() != expected_hex:
            issues.append(f"{label}: expected_output_hex differs from both references")
        if expected_result < 0 and primary[1] != b"":
            issues.append(f"{label}: error result must not write output")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
