"""Workload and oracle cross-reference; source-only helper, not run here."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import expected_output as primary

PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("algorithm") != "brace_range_expansion"
            or workload.get("function_symbol") != "brace_range_expansion"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity differs")
    for case in workload.get("cases", []):
        values = tuple(case.get("input_values", ()))
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        options = (capacity, output_is_null, input_is_null, input_length)
        primary_result = primary(values, *options)
        independent_result = independent(values, *options)
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_result != independent_result or primary_result != expected:
            issues.append(f"{case.get('id')}: fixture and references differ")
    return issues


if __name__ == "__main__":
    problems = verify_workload()
    if problems:
        raise SystemExit("\n".join(problems))
