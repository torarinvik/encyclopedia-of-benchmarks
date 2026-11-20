"""Compare the two references against pinned result codes and output bytes."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT_BYTES,
        PARSE_WORD_LIMIT as INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH,
        SCRATCH_LIMIT as INDEPENDENT_WORKSPACE_BYTES,
        expected_output as independent_expected_output,
    )
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_expected_output,
    )
except ImportError:
    from independent_oracle import (
        MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT_BYTES,
        PARSE_WORD_LIMIT as INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH,
        SCRATCH_LIMIT as INDEPENDENT_WORKSPACE_BYTES,
        expected_output as independent_expected_output,
    )
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_expected_output,
    )

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "broad_region", "narrow_corridor", "diagonal_contact", "seed_not_target",
    "capacity_failure", "extra_trailing_word", "null_input", "null_output",
}


def workload_issues(workload=None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    errors: list[str] = []
    if (workload.get("algorithm") != "flood_fill_breadth_first"
            or workload.get("function_symbol") != "flood_fill_breadth_first"
            or workload.get("abi") != "i64_array_bytes_output"):
        errors.append("workload identity or ABI is incorrect")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or MAX_PARSEABLE_INPUT_LENGTH != INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH
            or MAX_OUTPUT_BYTES != INDEPENDENT_MAX_OUTPUT_BYTES
            or WORKSPACE_BYTES != INDEPENDENT_WORKSPACE_BYTES):
        errors.append("workload bounds differ from the two reference contracts")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload contains no fixtures"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            errors.append("workload contains an unnamed fixture")
            continue
        case_id = case.get("id", "<unnamed>")
        if case_id in seen:
            errors.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"input length mismatch for {case_id}")
            continue
        args = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        first = primary_expected_output(values, **args)
        second = independent_expected_output(values, **args)
        if first != second:
            errors.append(f"references disagree for {case_id}")
            continue
        if first[0] != case.get("expected_result"):
            errors.append(f"result mismatch for {case_id}")
        if first[1].hex() != case.get("expected_output_hex"):
            errors.append(f"output mismatch for {case_id}")
    if not REQUIRED_CASES.issubset(seen):
        errors.append(f"missing fixtures: {sorted(REQUIRED_CASES - seen)}")
    return errors


if __name__ == "__main__":
    issues = workload_issues()
    if issues:
        raise SystemExit("\n".join(issues))
