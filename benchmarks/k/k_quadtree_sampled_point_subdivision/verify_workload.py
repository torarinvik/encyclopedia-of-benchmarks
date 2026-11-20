"""Pinned workload/reference comparison entry point; intentionally not run."""

import json
import struct
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_expected
    from .primary_oracle import expected_output as primary_expected
except ImportError:
    from independent_oracle import expected_output as independent_expected
    from primary_oracle import expected_output as primary_expected


def workload_issues() -> list[str]:
    path = Path(__file__).with_name("workload.json")
    workload = json.loads(path.read_text(encoding="utf-8"))
    issues: list[str] = []
    if workload.get("algorithm") != "k_quadtree_sampled_point_subdivision":
        issues.append("workload algorithm ID differs")
        return issues
    for case in workload.get("cases", []):
        words = case.get("expected_output_words", [])
        try:
            expected_bytes = b"".join(struct.pack("<q", word) for word in words)
        except (struct.error, TypeError):
            issues.append(f"{case.get('id')}: expected words are not signed-i64 values")
            continue
        if len(expected_bytes) > workload["output"]["maximum_output_bytes"]:
            issues.append(f"{case.get('id')}: pinned output exceeds package bound")
            continue
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case["expected_result"], expected_bytes)
        if primary_expected(case.get("input_values", []), **kwargs) != expected:
            issues.append(f"{case.get('id')}: primary reference differs from pinned fixture")
        if independent_expected(case.get("input_values", []), **kwargs) != expected:
            issues.append(f"{case.get('id')}: independent reference differs from pinned fixture")
    return issues


def check_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_workload()
