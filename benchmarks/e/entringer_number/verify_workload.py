"""Static workload/oracle agreement review; this file is not run here."""

from __future__ import annotations

import json
from pathlib import Path

from independent_oracle import entringer_direct_enumeration, entringer_number_independent
from primary_oracle import entringer_number

PACKAGE = Path(__file__).resolve().parent


def static_issues() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"bad input metadata: {case.get('id')}")
            continue
        expected = case.get("expected_result")
        if entringer_number(values) != expected:
            issues.append(f"primary mismatch: {case.get('id')}")
        if len(values) == 2:
            n, k = values
            if entringer_number_independent(values) != expected:
                issues.append(f"subset-DP mismatch: {case.get('id')}")
            if 0 <= n <= 7 and 0 <= k <= n:
                if entringer_direct_enumeration(n, k) != expected:
                    issues.append(f"direct-enumeration mismatch: {case.get('id')}")
    return issues
