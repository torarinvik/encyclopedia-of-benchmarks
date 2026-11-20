"""Static contract and fixture checks; this file is intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import (
    MAX_BITS as INDEPENDENT_MAX_BITS,
    MAX_WORKSPACE_BYTES as INDEPENDENT_MAX_WORKSPACE_BYTES,
    expected_output as independent_output,
)
from .primary_oracle import MAX_BITS, MAX_WORKSPACE_BYTES
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
WORKLOAD_PATH = PACKAGE / "workload.json"
REQUIRED_CASES = {
    "single-zero", "single-one", "binary-three", "binary-two", "binary-six",
    "leading-zeroes-represent-nine", "binary-seven", "sixty-four-one-bits",
    "empty-input", "null-input", "zero-bit-count", "negative-bit-count",
    "bit-count-over-bound", "truncated-bit-stream", "extra-trailing-word",
    "invalid-bit", "negative-bit", "malformed-before-output-capacity",
    "short-output-capacity", "null-output",
}


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "binary_divisibility_by_three_dfa"
            or workload.get("function_symbol") != "binary_divisibility_by_three_dfa"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI is incorrect")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("bit_count_range") != [1, MAX_BITS]
            or input_spec.get("maximum_valid_length") != MAX_BITS + 1
            or input_spec.get("maximum_parseable_length") != MAX_BITS + 2
            or output_spec.get("maximum_bytes") != 1
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        issues.append("workload framing differs from the bounded contract")
    if (MAX_BITS != INDEPENDENT_MAX_BITS
            or MAX_WORKSPACE_BYTES != INDEPENDENT_MAX_WORKSPACE_BYTES):
        issues.append("primary and independent references disagree on bounds")

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
        if not isinstance(values, list):
            issues.append(f"fixture input is not an array: {name}")
            continue
        if case.get("input_length") != len(values):
            issues.append(f"fixture input length is inconsistent: {name}")
            continue
        args = (values, case.get("output_capacity", 1),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
        primary = primary_output(*args)
        independent = independent_output(*args)
        if primary != independent:
            issues.append(f"references disagree: {name}")
        if primary[0] != case.get("expected_result"):
            issues.append(f"fixture result differs from references: {name}")
        if primary[1].hex() != case.get("expected_output_hex", "").lower():
            issues.append(f"fixture bytes differ from references: {name}")
        if primary[0] == -1 and primary[1]:
            issues.append(f"invalid fixture has output bytes: {name}")
        if primary[0] == -2 and primary[1]:
            issues.append(f"output-error fixture has output bytes: {name}")
    if not REQUIRED_CASES.issubset(seen):
        issues.append(f"missing fixtures: {sorted(REQUIRED_CASES - seen)}")

    profile = workload.get("generated_profile", {})
    if (profile.get("maximum_bit_count") != MAX_BITS
            or profile.get("maximum_input_length") != MAX_BITS + 1
            or profile.get("maximum_output_bytes") != 1):
        issues.append("maximum-size generated profile differs from the contract")
    maximum_zeros = [MAX_BITS, *([0] * MAX_BITS)]
    max_args = (maximum_zeros, 1, False, False, len(maximum_zeros))
    if (primary_output(*max_args) != (1, b"\x01")
            or independent_output(*max_args) != (1, b"\x01")):
        issues.append("maximum-size all-zero stream is not accepted by both references")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("workload issues: " + "; ".join(problems))
    print("binary_divisibility_by_three_dfa: fixtures are internally consistent")
