"""Pinned workload/reference comparison helper; intentionally not run."""

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
    workload = json.loads(Path(__file__).with_name("workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if workload.get("algorithm") != "k_quadtree_edge_distribution":
        return ["workload algorithm ID differs"]
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI differs")
    max_input = workload.get("input", {}).get("maximum_parseable_length")
    max_output = workload.get("output", {}).get("maximum_output_bytes")
    for case in workload.get("cases", []):
        ident = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if len(values) > max_input:
            issues.append(f"{ident}: frame exceeds parseable input bound")
            continue
        words = case.get("expected_output_words", [])
        try:
            expected_bytes = b"".join(struct.pack("<q", word) for word in words)
        except (struct.error, TypeError):
            issues.append(f"{ident}: expected output contains a non-i64 word")
            continue
        if len(expected_bytes) > max_output:
            issues.append(f"{ident}: expected output exceeds package bound")
            continue
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case["expected_result"], expected_bytes)
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
