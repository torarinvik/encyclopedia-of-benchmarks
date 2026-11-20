"""Static contract and fixture comparison for the stack flood-fill package."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "diagonal_region", "border_flood", "seed_not_target", "single_cell",
    "capacity_failure", "equal_colors_invalid", "invalid_seed", "empty_dimension",
    "color_out_of_i32", "extra_trailing_word", "null_input", "null_output",
}


def workload_issues(workload=None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("algorithm") != "flood_fill"
            or workload.get("function_symbol") != "flood_fill"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI is incorrect")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload framing, output, or scratch bounds differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload contains no fixtures"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("workload contains an unnamed fixture")
            continue
        name = case["id"]
        if name in seen:
            issues.append(f"duplicate fixture ID: {name}")
        seen.add(name)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input framing is inconsistent: {name}")
            continue
        args = (values, case.get("output_capacity"), case.get("output_is_null", False),
                case.get("input_is_null", False), case.get("input_length"))
        first = primary_output(*args)
        second = independent_output(*args)
        if first != second:
            issues.append(f"references disagree for {name}")
        if first[0] != case.get("expected_result"):
            issues.append(f"result differs from references for {name}")
        if first[1].hex() != case.get("expected_output_hex", "").lower():
            issues.append(f"output bytes differ from references for {name}")
    if not REQUIRED_CASES.issubset(seen):
        issues.append(f"missing fixtures: {sorted(REQUIRED_CASES - seen)}")
    return issues
