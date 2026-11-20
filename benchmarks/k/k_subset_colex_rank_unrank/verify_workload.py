"""Static workload/reference reconciliation; this module does not run ports."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return ["workload cases are missing"]
    required = {
        "zero-universe-empty-subset", "empty-subset-at-nonzero-universe",
        "rank-last-of-five-choose-three", "unrank-last-of-five-choose-three",
        "maximum-valid-frame-and-output-k-equals-n",
        "maximum-output-one-byte-short", "maximum-parseable-one-word-overlong",
        "invalid-unrank-count-boundary", "null-input-pointer", "null-output-pointer",
    }
    observed = {case.get("id") for case in cases if isinstance(case, dict)}
    for missing in sorted(required - observed):
        issues.append(f"required workload case missing: {missing}")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload case is not an object")
            continue
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"input framing mismatch: {case.get('id')}")
            continue
        expected = (case.get("expected_result"), case.get("expected_output_hex"))
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_output(values, **options)
        independent = independent_output(values, **options)
        pinned = (expected[0], bytes.fromhex(expected[1]))
        if primary != independent:
            issues.append(f"references disagree: {case.get('id')}")
        if primary != pinned:
            issues.append(f"fixture differs from references: {case.get('id')}")
        if len(values) > 20:
            issues.append(f"input exceeds parseable bound: {case.get('id')}")
        if case.get("output_capacity", 0) > 136:
            issues.append(f"capacity exceeds output bound: {case.get('id')}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("; ".join(issues))
