"""Compare pinned workload fixtures with both Python references only.

This helper does not load, compile, or call any native benchmark port.
"""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_expected_output
    from .primary_oracle import expected_output as primary_expected_output
except ImportError:
    from independent_oracle import expected_output as independent_expected_output
    from primary_oracle import expected_output as primary_expected_output

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text())
    errors: list[str] = []
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        arguments = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary_result, primary_bytes = primary_expected_output(values, **arguments)
        independent_result, independent_bytes = independent_expected_output(values, **arguments)
        if primary_result != independent_result or primary_bytes != independent_bytes:
            errors.append(f"the two references disagree for case {case_id}")
            continue
        if primary_result != case.get("expected_result"):
            errors.append(f"expected result mismatch for case {case_id}")
        expected_hex = case.get("expected_output_hex")
        if not isinstance(expected_hex, str) or primary_bytes.hex() != expected_hex:
            errors.append(f"expected output bytes mismatch for case {case_id}")
    return errors


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
