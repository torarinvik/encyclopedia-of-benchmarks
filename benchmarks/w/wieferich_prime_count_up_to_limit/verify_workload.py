"""Static workload/oracle reconciliation source; do not run in quiet mode."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import wieferich_prime_count_up_to_limit_independent
    from .primary_oracle import wieferich_prime_count_up_to_limit
except ImportError:
    from independent_oracle import wieferich_prime_count_up_to_limit_independent
    from primary_oracle import wieferich_prime_count_up_to_limit

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"invalid fixture framing: {case.get('id')}")
            continue
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if wieferich_prime_count_up_to_limit(values, **options) != expected:
            issues.append(f"primary reference mismatch: {case.get('id')}")
        if wieferich_prime_count_up_to_limit_independent(values, **options) != expected:
            issues.append(f"independent reference mismatch: {case.get('id')}")
    return issues
