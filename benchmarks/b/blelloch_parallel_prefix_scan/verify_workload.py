"""Compare the pinned workload to both references; not run while drafting."""

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
    ("Blelloch tree reference", primary_output),
    ("serial running-sum reference", independent_output),
)


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    for case in workload.get("cases", []):
        case_id = case.get("id", "<missing id>")
        try:
            expected = (case.get("expected_result"),
                        bytes.fromhex(case.get("expected_output_hex", "")))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: malformed expected output hex")
            continue
        observed = []
        for label, oracle in ORACLES:
            actual = oracle(
                case.get("input_values", []),
                capacity=case.get("output_capacity"),
                output_is_null=case.get("output_is_null", False),
                input_is_null=case.get("input_is_null", False),
                input_length=case.get("input_length"),
            )
            observed.append(actual)
            if actual != expected:
                issues.append(f"{case_id}: {label} differs from the pinned result/output")
        if len(set(observed)) > 1:
            issues.append(f"{case_id}: the references disagree")
    return issues
