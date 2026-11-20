"""Static metadata and fixture review; this source is intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_N as INDEPENDENT_MAX_N,
        MAX_WORKSPACE_BYTES as INDEPENDENT_MAX_WORKSPACE_BYTES,
        expected_result as independent_result,
    )
    from .primary_oracle import (
        MAX_N,
        MAX_RESULT,
        MAX_VALID_INPUT_LENGTH,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result as primary_result,
    )
except ImportError:
    from independent_oracle import (
        MAX_N as INDEPENDENT_MAX_N,
        MAX_WORKSPACE_BYTES as INDEPENDENT_MAX_WORKSPACE_BYTES,
        expected_result as independent_result,
    )
    from primary_oracle import (
        MAX_N,
        MAX_RESULT,
        MAX_VALID_INPUT_LENGTH,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result as primary_result,
    )

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "empty-frame", "truncated-frame", "missing-items", "null-input",
    "single-item-three-halves", "single-item-one-third", "single-item-sixth",
    "single-item-maximum-ratio", "best-single-item", "both-items-required",
    "all-items-required", "denominator-threshold-selects-pair",
    "threshold-prefers-one-third", "zero-numerators",
    "maximum-frame-and-total-weight", "extra-word", "negative-n", "n-over-bound",
    "zero-required-denominator", "total-denominator-too-small", "numerator-over-bound",
    "zero-item-denominator", "i64-min-n", "i64-max-denominator",
}


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload root must be an object"]
    if (workload.get("algorithm") != "fractional_programming_ratio_knapsack_binary_search"
            or workload.get("function_symbol") != "fractional_programming_ratio_knapsack_binary_search"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI is incorrect")

    input_spec = workload.get("input", {})
    if (input_spec.get("n_range") != [1, MAX_N]
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("encoding") != "[n,W,(a_i,b_i)*n]"
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or MAX_N != INDEPENDENT_MAX_N
            or MAX_WORKSPACE_BYTES != INDEPENDENT_MAX_WORKSPACE_BYTES):
        issues.append("input or workspace bounds differ from the package contract")
    if workload.get("output", {}).get("valid_result_range") != [0, MAX_RESULT]:
        issues.append("output range differs from the package contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixtures"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("workload contains an unnamed fixture")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture framing is invalid: {case_id}")
            continue
        args = (values, case.get("input_is_null", False), case.get("input_length"))
        primary = primary_result(*args)
        independent = independent_result(*args)
        if primary != independent:
            issues.append(f"references disagree: {case_id}")
        if primary != case.get("expected_result"):
            issues.append(f"fixture differs from references: {case_id}")
    if not REQUIRED_CASES.issubset(seen):
        issues.append(f"missing fixtures: {sorted(REQUIRED_CASES - seen)}")

    profile = workload.get("generated_profile", {})
    if (profile.get("maximum_n") != MAX_N
            or profile.get("maximum_scaled_result") != MAX_RESULT):
        issues.append("generated result profile differs from the contract")
    maximum_ratio = [1, 1, 1000, 1]
    if (primary_result(maximum_ratio) != MAX_RESULT
            or independent_result(maximum_ratio) != MAX_RESULT):
        issues.append("maximum scaled ratio is not reproduced by both references")
    maximum_frame = [12, 12, *([1000, 1] * 12)]
    if len(maximum_frame) != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum input frame construction differs from the contract")
    if (primary_result(maximum_frame + [0]) != -1
            or independent_result(maximum_frame + [0]) != -1):
        issues.append("maximum parseable trailing word is not rejected")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("workload issues: " + "; ".join(problems))
    print("fractional_programming_ratio_knapsack_binary_search: workload metadata is consistent")
