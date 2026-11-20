"""Static workload/reference agreement checks; this module is not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent
SYMBOL = "grid_shortest_path_obstacle_elimination"
SOURCE_URL = "https://leetcode.com/problems/shortest-path-in-a-grid-with-obstacles-elimination/"
BFS_URL = "https://cp-algorithms.com/graph/breadth-first-search.html"
REQUIRED_CASES = {
    "single_free_cell", "open_rectangle", "one_elimination_crosses_cut",
    "insufficient_budget", "one_row_two_obstacles", "maximum_frame_open_grid",
    "invalid_zero_rows", "invalid_budget", "blocked_start", "nonbinary_cell",
    "short_frame", "trailing_word", "maximum_parseable_trailing_word", "null_input",
}


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    source = workload.get("source", {})
    input_meta = workload.get("input", {})
    if (source.get("title_page") != SOURCE_URL
            or source.get("algorithm_reference") != BFS_URL
            or input_meta.get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("workspace", {}).get("bytes") != primary_oracle.MAX_WORKSPACE_BYTES):
        issues.append("source provenance or bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture must have a string id")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        primary = primary_oracle.expected_result(values, is_null, length)
        independent = independent_oracle.expected_result(values, is_null, length)
        if primary != independent:
            issues.append(f"references disagree for {case_id}")
        if primary != expected:
            issues.append(f"pinned result differs for {case_id}")
    if seen != REQUIRED_CASES:
        issues.append(f"fixture IDs differ: {sorted(seen ^ REQUIRED_CASES)}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
