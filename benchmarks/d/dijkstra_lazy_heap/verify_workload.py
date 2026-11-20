"""Check bounded fixtures against independent primary and Bellman–Ford references."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import check_inventory
from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary

PACKAGE = Path(__file__).resolve().parent


def verify_workload(workload=None) -> list[str]:
    issues = check_inventory()
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
        actual_primary = primary(case.get("vertices"), case.get("edges"), case.get("source"))
        actual_independent = independent(case.get("vertices"), case.get("edges"), case.get("source"))
        expected = (case.get("expected_status"), case.get("expected_distances"))
        if actual_primary != expected:
            issues.append(f"fixture differs from lazy-heap oracle: {case.get('id')}")
        if actual_independent != expected:
            issues.append(f"fixture differs from Bellman–Ford oracle: {case.get('id')}")
        if actual_primary != actual_independent:
            issues.append(f"references disagree: {case.get('id')}")
    return issues
