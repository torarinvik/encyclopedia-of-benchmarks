"""Compare the published graph fixtures with Prim and independent Kruskal."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_result as kruskal
from .primary_oracle import expected_result as indexed_heap_prim

PACKAGE = Path(__file__).resolve().parent


def verify_workload(workload=None) -> list[str]:
    issues = static_issues()
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            issues.append("invalid workload case")
            continue
        values = case.get("input_values")
        expected = case.get("expected_result")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"packed length mismatch: {case.get('id')}")
            continue
        primary = indexed_heap_prim(values)
        independent = kruskal(values)
        if primary != expected:
            issues.append(f"fixture differs from indexed-heap Prim: {case.get('id')}")
        if independent != expected:
            issues.append(f"fixture differs from independent Kruskal: {case.get('id')}")
        if primary != independent:
            issues.append(f"references disagree: {case.get('id')}")
    return issues
