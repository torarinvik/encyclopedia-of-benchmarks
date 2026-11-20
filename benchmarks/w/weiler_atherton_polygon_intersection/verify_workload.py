"""Static reference/workload reconciler; authored only, not run."""

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
    errors: list[str] = []
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
        name = case.get("id", "<missing-id>")
        if primary != independent:
            errors.append(f"references disagree for {name}")
        if primary[0] != case.get("expected_result"):
            errors.append(f"result mismatch for {name}")
        if case.get("oracle_derived_output") is True:
            if "expected_output_hex" in case:
                errors.append(f"derived output must not pin bytes for {name}")
            if primary[0] >= 0 and len(primary[1]) != primary[0]:
                errors.append(f"derived output length mismatch for {name}")
        elif primary[1].hex() != case.get("expected_output_hex"):
            errors.append(f"byte fixture mismatch for {name}")
    return errors


if __name__ == "__main__":
    issues = verify_workload()
    if issues:
        raise SystemExit("\n".join(issues))
