"""Compare the pinned sieve workload with both mathematical references."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import prime_count as independent_count
from .primary_oracle import prime_count as primary_count

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    for case in data["cases"]:
        limit = case["input_value"]
        expected = case["expected_result"]
        for label, reference in (("primary", primary_count),
                                 ("independent", independent_count)):
            actual = reference(limit)
            if actual != expected:
                issues.append(
                    f"{case['id']}: {label} expected {expected}, got {actual}"
                )
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
