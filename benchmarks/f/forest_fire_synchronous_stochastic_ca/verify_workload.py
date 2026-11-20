"""Compare pinned workload results against both Python references only."""

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
        result_a, bytes_a = primary_expected_output(values, **arguments)
        result_b, bytes_b = independent_expected_output(values, **arguments)
        if result_a != result_b or bytes_a != bytes_b:
            errors.append(f"the references disagree for case {case_id}")
            continue
        if result_a != case.get("expected_result"):
            errors.append(f"pinned result differs for case {case_id}")
        expected_hex = case.get("expected_output_hex")
        if not isinstance(expected_hex, str) or bytes_a.hex() != expected_hex:
            errors.append(f"pinned output bytes differ for case {case_id}")
    return errors


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
