"""Static workload/oracle reconciliation; this file is authored, not run."""

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


def verify_workload() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text())
    issues: list[str] = []
    for case in workload.get("cases", []):
        args = (
            case.get("input_values"),
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        first = primary_output(*args)
        second = independent_output(*args)
        case_id = case.get("id", "<missing-id>")
        if first != second:
            issues.append(f"references disagree for {case_id}")
        if first[0] != case.get("expected_result"):
            issues.append(f"expected result mismatch for {case_id}")
        if first[1].hex() != case.get("expected_output_hex"):
            issues.append(f"expected bytes mismatch for {case_id}")
    return issues


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
