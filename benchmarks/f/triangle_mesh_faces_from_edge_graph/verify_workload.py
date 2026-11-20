"""Static workload/reference reconciliation; authored only, not run."""

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
        arguments = (
            case.get("input_values"),
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        primary = primary_output(*arguments)
        independent = independent_output(*arguments)
        case_id = case.get("id", "<missing-id>")
        if primary != independent:
            issues.append(f"references disagree for {case_id}")
        if primary[0] != case.get("expected_result"):
            issues.append(f"expected result mismatch for {case_id}")
        if primary[1].hex() != case.get("expected_output_hex"):
            issues.append(f"expected bytes mismatch for {case_id}")
    return issues


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
