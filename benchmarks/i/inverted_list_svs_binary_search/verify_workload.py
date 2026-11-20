"""Static consistency checks for bounded SvS fixtures and both references."""
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


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "inverted_list_svs_binary_search"
            or workload.get("function_symbol") != "inverted_list_svs_binary_search"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("list_count_range") != [2, 8]
            or input_spec.get("each_list_length_range") != [0, 32]):
        issues.append("input frame bounds differ from the primary reference")
    output_spec = workload.get("output", {})
    if (output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_spec.get("maximum_values") != 32):
        issues.append("output maximum differs from the primary reference")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace differs from the primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload must contain named fixture objects"]
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
        if (primary != independent or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")):
            issues.append(f"fixture/reference mismatch: {case_id}")
    return issues


def verify() -> list[str]:
    return workload_issues()


if __name__ == "__main__":
    print("checked static SvS workload source")
