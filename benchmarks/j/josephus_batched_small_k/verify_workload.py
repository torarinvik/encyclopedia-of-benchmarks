"""Static workload/oracle agreement review; this file is not run here."""

from __future__ import annotations

import json
from pathlib import Path

from independent_oracle import josephus_linear, josephus_simulated
from primary_oracle import josephus_batched_small_k


PACKAGE = Path(__file__).resolve().parent


def static_issues() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if workload.get("algorithm") != "josephus_batched_small_k":
        issues.append("workload algorithm id mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"bad input buffer metadata: {case.get('id')}")
            continue
        expected = case.get("expected_result")
        actual = josephus_batched_small_k(values)
        if actual != expected:
            issues.append(f"primary result mismatch: {case.get('id')}")
        linear = josephus_linear(values)
        if linear != expected:
            issues.append(f"linear reference mismatch: {case.get('id')}")
        if len(values) == 2 and 1 <= values[0] <= 256 and 1 <= values[1] <= 32:
            if josephus_simulated(*values) != expected:
                issues.append(f"list simulator mismatch: {case.get('id')}")
    return issues
