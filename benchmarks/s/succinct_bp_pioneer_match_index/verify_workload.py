"""Source-only workload/reference reconciliation helper; do not execute here."""

from __future__ import annotations

import json
from pathlib import Path

from independent_oracle import expected_output as independent_output
from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ["workload.json is not valid JSON"]
    seen: set[str] = set()
    if workload.get("algorithm") != "succinct_bp_pioneer_match_index":
        issues.append("workload algorithm id mismatch")
    for case in workload.get("cases", []):
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append("case IDs must be unique strings")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case_id}: malformed input framing")
            continue
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary_result, primary_bytes = primary_output(values, **kwargs)
        independent_result, independent_bytes = independent_output(values, **kwargs)
        if (primary_result, primary_bytes) != (independent_result, independent_bytes):
            issues.append(f"{case_id}: references disagree")
        if primary_result != case.get("expected_result"):
            issues.append(f"{case_id}: pinned result disagrees")
        if primary_bytes.hex() != case.get("expected_output_hex"):
            issues.append(f"{case_id}: pinned output bytes disagree")
    return issues
