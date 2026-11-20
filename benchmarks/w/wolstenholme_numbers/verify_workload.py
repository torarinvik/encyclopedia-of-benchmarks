"""Source-only workload/reference consistency helper; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_INTERMEDIATE_NUMERATOR, MAX_LCM, MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_RESULT,
        MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES, expected_result,
    )
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import (
        MAX_INTERMEDIATE_NUMERATOR, MAX_LCM, MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_RESULT,
        MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES, expected_result,
    )

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (data.get("algorithm") != "wolstenholme_numbers"
            or data.get("function_symbol") != "wolstenholme_numbers"
            or data.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    input_meta = data.get("input", {})
    output_meta = data.get("output", {})
    if (input_meta.get("n_range") != [1, MAX_N]
            or input_meta.get("exact_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload input bounds differ")
    if (output_meta.get("valid_result_range") != [1, MAX_RESULT]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("workload output bounds differ")
    if data.get("bounds", {}).get("maximum_common_denominator") != MAX_LCM:
        issues.append("workload common-denominator bound differs")
    if data.get("bounds", {}).get("maximum_pre_reduction_numerator_bound_exclusive") != MAX_INTERMEDIATE_NUMERATOR:
        issues.append("workload intermediate-numerator bound differs")
    if data.get("bounds", {}).get("maximum_result") != MAX_RESULT:
        issues.append("workload maximum result differs")
    if data.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workload workspace differs")
    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"invalid frame: {case_id}")
            continue
        is_null = case.get("input_is_null", False)
        if type(is_null) is not bool:
            issues.append(f"invalid null marker: {case_id}")
            continue
        if not is_null and length != len(values):
            issues.append(f"frame length mismatch: {case_id}")
        kwargs = {"input_is_null": is_null, "input_length": length}
        primary = expected_result(values, **kwargs)
        independent = independent_result(values, **kwargs)
        expected = case.get("expected_result")
        if primary != expected or independent != expected:
            issues.append(f"reference result differs: {case_id}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
