"""Package-local, non-executed fixture/reference consistency API."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle
    import primary_oracle

PACKAGE_DIR = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 12
MAX_PARSEABLE_INPUT_LENGTH = 13
MAX_RESULT = 90000
WORKSPACE_BYTES = 1024


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE_DIR / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload.json: {error}"]

    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI must be i64_array_scalar")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    workspace_meta = workload.get("workspace", {})
    if input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length differs from the package bound")
    if input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length differs from the package bound")
    if output_meta.get("valid_result_range") != [0, MAX_RESULT]:
        issues.append("result range differs from the package bound")
    if workspace_meta.get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace cap differs from the package bound")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            issues.append(f"case has missing or duplicate id: {case_id!r}")
        else:
            seen.add(case_id)
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be a list")
            continue
        if type(input_length) is not int or input_length != len(values):
            issues.append(f"{case_id}: input_length must equal input_values length")
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"{case_id}: input exceeds parseable frame limit")
        if type(input_is_null) is not bool:
            issues.append(f"{case_id}: input_is_null must be a boolean")
        expected = case.get("expected_result")
        if type(expected) is not int:
            issues.append(f"{case_id}: expected_result must be an integer")
            continue
        for name, oracle in (("primary", primary_oracle),
                             ("independent", independent_oracle)):
            actual = oracle.expected_result(
                values,
                input_is_null=input_is_null,
                input_length=input_length,
            )
            if actual != expected:
                issues.append(f"{case_id}: {name} reference differs from pinned result")
        if expected >= 0 and expected > MAX_RESULT:
            issues.append(f"{case_id}: result exceeds the maximum bound")

    required_ids = {
        "one-symbol-ternary", "one-symbol-quaternary",
        "ternary-five-equal-tie", "quaternary-seven-equal-tie",
        "maximum-valid-frame", "invalid-ternary-count-two",
        "invalid-quaternary-count-three", "trailing-word-at-parseable-bound",
        "null-input",
    }
    missing = required_ids - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues

