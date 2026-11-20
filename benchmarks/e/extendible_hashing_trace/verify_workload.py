"""Static fixture/reference reconciliation helper; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:  # direct import from a package directory
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "extendible_hashing_trace":
        issues.append("workload algorithm identifier mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload case is not an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            issues.append(f"invalid or repeated case id: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        null_input = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"{case_id}: missing array frame or integer input_length")
            continue
        if type(null_input) is not bool or (not null_input and length != len(values)):
            issues.append(f"{case_id}: inconsistent null/input length metadata")
        if null_input and length != 0:
            issues.append(f"{case_id}: null input must declare length zero")
        if type(expected) is not int:
            issues.append(f"{case_id}: expected_result must be an integer")
            continue
        actual_primary = primary_oracle.expected_result(
            values, input_is_null=null_input, input_length=length)
        actual_independent = independent_oracle.expected_result(
            values, input_is_null=null_input, input_length=length)
        if actual_primary != expected:
            issues.append(f"{case_id}: primary result differs from pinned result")
        if actual_independent != expected:
            issues.append(f"{case_id}: independent result differs from pinned result")
        if actual_primary != actual_independent:
            issues.append(f"{case_id}: references disagree")
    required = {
        "empty-trace", "first-split-and-query", "split-then-coalesce-and-shrink",
        "duplicate-insert-and-membership", "cascading-prefix-splits",
        "maximum-depth-eight-split", "deep-buddy-coalescing",
        "maximum-valid-frame", "maximum-parseable-trailing-word", "null-input",
    }
    if not required.issubset(seen):
        issues.append("required boundary/split/coalesce fixtures are missing")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
