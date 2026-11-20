"""Static workload/oracle agreement helper; do not run during quiet-mode edits."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import taxicab_number_minimum_representations_independent
    from .primary_oracle import taxicab_number_minimum_representations
except ImportError:
    from independent_oracle import taxicab_number_minimum_representations_independent
    from primary_oracle import taxicab_number_minimum_representations

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"invalid input framing: {case.get('id')}")
            continue
        expected = case.get("expected_result")
        primary = taxicab_number_minimum_representations(values)
        independent = taxicab_number_minimum_representations_independent(values)
        if primary != expected:
            issues.append(f"primary mismatch: {case.get('id')}")
        if independent != expected:
            issues.append(f"independent mismatch: {case.get('id')}")
    return issues
