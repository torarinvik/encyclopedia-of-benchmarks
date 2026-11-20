"""Static package contract and fixture checks; intentionally not run."""

from __future__ import annotations

import json
from math import factorial
from pathlib import Path

from .independent_oracle import (
    MAX_N as INDEPENDENT_MAX_N,
    MAX_WORKSPACE_BYTES as INDEPENDENT_MAX_WORKSPACE_BYTES,
    expected_result as independent_result,
)
from .primary_oracle import (
    MAX_N,
    MAX_RESULT,
    MAX_WORKSPACE_BYTES,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
WORKLOAD_PATH = PACKAGE / "workload.json"
REQUIRED_CASES = {
    "empty-frame", "truncated-frame", "extra-word", "null-input",
    "empty-permutation", "single-permutation", "zero-descents", "one-descent",
    "four-elements-one-descent", "five-elements-two-descents",
    "seven-elements-three-descents", "ten-elements-four-descents",
    "maximum-n-minimum-k", "maximum-n-maximum-k", "negative-n", "n-over-bound",
    "negative-k", "k-equals-n", "i64-min-n", "i64-max-k",
}


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "eulerian_number"
            or workload.get("function_symbol") != "eulerian_number"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI is incorrect")
    input_spec = workload.get("input", {})
    if (input_spec.get("n_range") != [0, MAX_N]
            or input_spec.get("maximum_valid_length") != 2
            or input_spec.get("maximum_parseable_length") != 3
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or MAX_N != INDEPENDENT_MAX_N
            or MAX_WORKSPACE_BYTES != INDEPENDENT_MAX_WORKSPACE_BYTES):
        issues.append("input/workspace bounds differ from the package contract")
    if workload.get("output", {}).get("valid_result_range") != [1, MAX_RESULT]:
        issues.append("output result bound differs from the package contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixtures"]
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
            issues.append(f"fixture framing is invalid: {name}")
            continue
        primary = primary_result(values, case.get("input_is_null", False),
                                 case.get("input_length"))
        independent = independent_result(values, case.get("input_is_null", False),
                                          case.get("input_length"))
        if primary != independent:
            issues.append(f"references disagree: {name}")
        if primary != case.get("expected_result"):
            issues.append(f"fixture result differs from references: {name}")
    if not REQUIRED_CASES.issubset(seen):
        issues.append(f"missing fixtures: {sorted(REQUIRED_CASES - seen)}")

    profile = workload.get("generated_profile", {})
    if (profile.get("maximum_n") != MAX_N
            or profile.get("maximum_row_sum") != MAX_RESULT):
        issues.append("maximum-row profile differs from the contract")
    max_row_sum = sum(primary_result([MAX_N, k]) for k in range(MAX_N))
    independent_row_sum = sum(independent_result([MAX_N, k]) for k in range(MAX_N))
    if max_row_sum != factorial(MAX_N) or independent_row_sum != factorial(MAX_N):
        issues.append("maximum Eulerian row does not sum to n! under both references")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("workload issues: " + "; ".join(problems))
    print("eulerian_number: fixtures and references are internally consistent")
