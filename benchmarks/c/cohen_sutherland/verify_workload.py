"""Metadata-only check that fixtures agree with both independent methods."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle
except ImportError:
    import independent_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        import sys
        sys.path.insert(0, str(ROOT / "benchmarks"))
        from cohen_sutherland_oracle import expected_result as primary_expected
    except (OSError, json.JSONDecodeError, ImportError) as error:
        return [f"cannot load workload references: {error}"]

    issues: list[str] = []
    if workload.get("algorithm") != "cohen_sutherland":
        issues.append("workload algorithm name differs from the package")
    if workload.get("function_symbol") != "cohen_sutherland":
        issues.append("workload symbol differs from the package")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_float64_call":
        issues.append("workload comparison model differs from the scalar ABI")
    seen: set[str] = set()
    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id", "<missing>")
        values = case.get("input_values")
        if case_id in seen:
            issues.append(f"duplicate workload fixture id: {case_id}")
        seen.add(case_id)
        if (not isinstance(values, list) or type(case.get("input_length")) is not int
                or case["input_length"] != len(values)
                or any(type(value) is not int for value in values)):
            issues.append(f"invalid workload input framing in {case_id}")
            continue
        expected = case.get("expected_result")
        if type(expected) not in (int, float):
            issues.append(f"missing numeric expected_result in {case_id}")
            continue
        primary_value = primary_expected(values)
        independent_value = independent_oracle.expected_result(values)
        if not independent_oracle.agrees(primary_value, independent_value):
            issues.append(f"primary and independent references disagree for {case_id}")
        if not independent_oracle.agrees(expected, primary_value):
            issues.append(f"pinned expected_result differs from references for {case_id}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
