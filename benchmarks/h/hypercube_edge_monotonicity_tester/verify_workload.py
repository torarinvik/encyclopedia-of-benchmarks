"""Compare pinned fixtures against both references; not run while drafting."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Callable

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
Oracle = Callable[..., tuple[int, bytes]]
ORACLES: tuple[tuple[str, Oracle], ...] = (
    ("source-ordered edge-tester oracle", primary_output),
    ("independent full-trace oracle", independent_output),
)


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    for group in ("cases", "invalid_cases", "capacity_cases"):
        for case in workload.get(group, []):
            case_id = case.get("id", "<missing id>")
            try:
                expected = (case.get("expected_result"),
                            bytes.fromhex(case.get("expected_output_hex", "")))
            except (TypeError, ValueError):
                issues.append(f"{case_id}: malformed expected-output hex")
                continue
            outputs = []
            for label, oracle in ORACLES:
                actual = oracle(
                    case.get("input_values", []),
                    capacity=case.get("output_capacity"),
                    output_is_null=case.get("output_is_null", False),
                    input_is_null=case.get("input_is_null", False),
                    input_length=case.get("input_length"),
                )
                outputs.append(actual)
                if actual != expected:
                    issues.append(f"{case_id}: {label} differs from pinned result/output")
            if len(set(outputs)) > 1:
                issues.append(f"{case_id}: primary and independent references disagree")
    return issues
