"""Static fixture comparison for the bounded ECDSA package; not run here."""
from __future__ import annotations

import json
from pathlib import Path

from .primary_oracle import expected_output as primary_output
from .independent_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid workload JSON: {error}"]
    if workload.get("algorithm") != "ecdsa_signature_verification":
        issues.append("unexpected workload algorithm")
    if workload.get("function_symbol") != "ecdsa_signature_verification":
        issues.append("unexpected workload symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected workload ABI")
    if workload.get("workspace", {}).get("bytes") != 512:
        issues.append("unexpected workspace declaration")
    seen: set[str] = set()
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        if case_id in seen:
            issues.append(f"duplicate case id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        output_is_null = bool(case.get("output_is_null", False))
        primary = primary_output(values, capacity, output_is_null)
        independent = independent_output(values, capacity, output_is_null)
        if primary != independent:
            issues.append(f"oracle disagreement in {case_id}: {primary!r} != {independent!r}")
        expected_result = case.get("expected_result")
        expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        if primary != (expected_result, expected_bytes):
            issues.append(f"fixture mismatch in {case_id}: {primary!r}")
        if case.get("input_is_null") and values != []:
            issues.append(f"null-input framing mismatch in {case_id}")
        if case.get("input_length") != len(values):
            issues.append(f"input-length mismatch in {case_id}")
    return issues


if __name__ == "__main__":
    errors = workload_issues()
    if errors:
        raise SystemExit("\n".join(errors))
    print("ECDSA workload fixtures match both references.")
