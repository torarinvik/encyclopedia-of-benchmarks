"""Static fixture reconciliation API; this file is intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:  # allow direct execution by repository tooling
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid workload metadata: {error}"]
    if (workload.get("algorithm") != "bk_tree_edit_distance_search"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != 27
            or workload.get("input", {}).get("maximum_parseable_length") != 28
            or workload.get("output", {}).get("maximum_result") != 14112
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("workload identity or bounded ABI metadata differs from the package contract")
    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids):
        issues.append("workload fixture IDs must be unique objects")
    required_ids = {
        "empty-dictionary-empty-batch", "empty-dictionary-queries", "empty-word-exact",
        "zero-radius-exact-and-miss", "radius-one-overlap", "metric-pruning-radius-two",
        "maximum-valid-frame", "maximum-parseable-trailing-word", "invalid-radius",
        "duplicate-dictionary-word", "invalid-active-symbol", "nonzero-unused-symbol",
        "empty-frame", "null-input", "signed-minimum", "signed-maximum",
    }
    if set(ids) != required_ids:
        issues.append("workload fixture identifiers differ from the reviewed boundary set")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool
                or (is_null and length != 0)
                or (not is_null and length != len(values))):
            issues.append(f"invalid ABI framing for fixture {case.get('id')}")
            continue
        expected = case.get("expected_result")
        primary = primary_oracle.expected_result(values, is_null, length)
        independent = independent_oracle.expected_result(values, is_null, length)
        if primary != expected:
            issues.append(f"primary oracle disagrees with fixture {case.get('id')}")
        if independent != expected:
            issues.append(f"independent oracle disagrees with fixture {case.get('id')}")
    return issues


def verify_workload() -> None:
    problems = workload_issues()
    if problems:
        raise AssertionError("\n".join(problems))


if __name__ == "__main__":
    verify_workload()
