"""Static workload/reference reconciler; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_expected
    from .primary_oracle import expected_output as primary_expected
except ImportError:
    from independent_oracle import expected_output as independent_expected
    from primary_oracle import expected_output as primary_expected


def workload_issues() -> list[str]:
    workload = json.loads(Path(__file__).with_name("workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if workload.get("algorithm") != "k_mismatch_longest_extension_table":
        return ["workload algorithm ID differs"]
    for case in workload.get("cases", []):
        ident = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if len(values) > workload["input"]["maximum_parseable_length"]:
            issues.append(f"{ident}: frame exceeds parseable input bound")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case.get("expected_output_hex", "")))
        except (KeyError, ValueError, TypeError):
            issues.append(f"{ident}: expected output hex is malformed")
            continue
        if len(expected[1]) > workload["output"]["maximum_output_bytes"]:
            issues.append(f"{ident}: expected output exceeds output bound")
            continue
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        if primary_expected(values, **kwargs) != expected:
            issues.append(f"{ident}: primary reference differs from pinned fixture")
        if independent_expected(values, **kwargs) != expected:
            issues.append(f"{ident}: independent reference differs from pinned fixture")
    return issues


def check_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_workload()
