"""Static fixture/reference reconciliation; not executed during drafting."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues(workload: object | None = None) -> list[str]:
    try:
        if workload is None:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid workload JSON: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    if (workload.get("algorithm") != "gpsr_perimeter_recovery_trace"
            or workload.get("abi") != "i64_array_bytes_output"):
        return ["workload identity or ABI differs"]
    issues: list[str] = []
    for case in workload.get("cases", []):
        args = (case.get("input_values"), case.get("output_capacity"),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
        wanted = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        for label, oracle in (("primary", primary_output), ("independent", independent_output)):
            if oracle(*args) != wanted:
                issues.append(f"{case.get('id')}: {label} reference differs from pinned bytes")
    return issues


def verify_workload(workload: object | None = None) -> list[str]:
    return workload_issues(workload)


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
