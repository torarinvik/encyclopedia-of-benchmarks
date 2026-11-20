"""Static workload-to-reference consistency source; not auto-run."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import (
    MAX_ALPHABET,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN,
    MAX_TEXT,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary_expected_output,
)

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "renamed-pattern-at-two-separated-starts",
    "failure-link-fallback-and-overlapping-matches",
    "bijection-pattern-mismatch",
    "pattern-longer-than-text",
    "empty-text",
    "maximum-valid-frame-single-occurrence",
    "maximum-output-rejected-one-byte-short",
    "alphabet-size-out-of-range",
    "symbol-out-of-range",
    "signed-minimum-symbol-rejected",
    "trailing-word-rejected",
    "short-output-capacity",
    "null-input",
    "null-output",
}


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]

    if (workload.get("algorithm") != "parameterized_pattern_matching_kmp"
            or workload.get("function_symbol") != "parameterized_pattern_matching_kmp"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("algorithm, symbol, or ABI differs from the package contract")
    input_spec = workload.get("input", {})
    if (input_spec.get("text_length_range") != [0, MAX_TEXT]
            or input_spec.get("pattern_length_range") != [1, MAX_PATTERN]
            or input_spec.get("alphabet_size_range") != [1, MAX_ALPHABET]
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input bounds differ from the references")
    output_spec = workload.get("output", {})
    if output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("output bound differs from the references")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace bound differs from the primary reference")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["cases must be a list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("every workload case must be an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate case ID: {case_id!r}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"input frame is missing for {case_id}")
            continue
        if not case.get("input_is_null", False) and length != len(values):
            issues.append(f"input length differs from frame for {case_id}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"expected output is malformed for {case_id}")
            continue
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": length,
        }
        for label, reference in (("primary", primary_expected_output),
                                 ("independent", independent_expected_output)):
            if reference(values, **options) != expected:
                issues.append(f"{label} reference differs from fixture {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("workload case IDs differ from the reviewed inventory")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
