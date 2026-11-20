"""Source-only consistency helper for the suffix-tray workload."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "suffix_tray_pattern_query" or
            workload.get("function_symbol") != "suffix_tray_pattern_query" or
            workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH or
            input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH or
            input_spec.get("alphabet_size_range") != [2, 4] or
            input_spec.get("text_length_range") != [1, 12] or
            input_spec.get("pattern_length_range") != [1, 8]):
        issues.append("input frame bounds differ from primary reference")
    output_spec = workload.get("output", {})
    if output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("output bound differs from primary reference")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace differs from primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload must contain fixture objects"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("fixture is not an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate fixture ID: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"input framing mismatch: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"input exceeds parseable bound: {case_id}")
            continue
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        if (primary != independent or primary[0] != case.get("expected_result") or
                primary[1].hex() != case.get("expected_output_hex")):
            issues.append(f"fixture/reference mismatch: {case_id}")
    return issues


def verify_workload(workload: dict | None = None) -> list[str]:
    return workload_issues(workload)


if __name__ == "__main__":
    print("static suffix-tray workload source is available")
