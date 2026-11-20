"""Static workload/reference comparison helper, not invoked during drafting."""

from __future__ import annotations

try:
    from benchmarks.minimum_parenthesis_removal_bfs_oracle import expected_output as primary
    from benchmarks.minimum_parenthesis_removal_bfs_independent_oracle import expected_output as independent
except ImportError:
    from minimum_parenthesis_removal_bfs_oracle import expected_output as primary
    from minimum_parenthesis_removal_bfs_independent_oracle import expected_output as independent

from pathlib import Path
import json


def workload_issues() -> list[str]:
    path = Path(__file__).with_name("workload.json")
    try:
        workload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    issues: list[str] = []
    for case in workload.get("cases", []):
        values = case.get("input_values")
        capacity = case.get("output_capacity", 4354)
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        try:
            expected = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"invalid expected hex: {case.get('id')}")
            continue
        args = (values, capacity, output_is_null, input_is_null, input_length)
        got_primary = primary(*args)
        got_independent = independent(*args)
        pinned = (case.get("expected_result"), expected)
        if got_primary != pinned:
            issues.append(f"primary reference differs from fixture: {case.get('id')}")
        if got_independent != pinned:
            issues.append(f"independent reference differs from fixture: {case.get('id')}")
        if got_primary != got_independent:
            issues.append(f"references disagree: {case.get('id')}")
    return issues
