"""Static fixture/reference reconciliation helper; not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle  # type: ignore[no-redef]
    import primary_oracle  # type: ignore[no-redef]

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("algorithm") != "sieve_of_pritchard"
            or workload.get("function_symbol") != "sieve_of_pritchard"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs from the package")
    input_spec = workload.get("input", {})
    workspace = workload.get("workspace", {})
    if (input_spec.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or workspace.get("bytes") != primary_oracle.MAX_WORKSPACE_BYTES):
        issues.append("workload framing or workspace differs from the primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["cases must be a list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("cases contains a non-object fixture")
            continue
        case_id = case.get("id", "<missing>")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"missing or duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool
                or (is_null and length != 0)
                or (not is_null and length != len(values))
                or length > primary_oracle.MAX_PARSEABLE_INPUT_LENGTH):
            issues.append(f"invalid input framing for {case_id}")
            continue
        expected = case.get("expected_result")
        kwargs = {"input_is_null": is_null, "input_length": length}
        for label, oracle in (("primary", primary_oracle),
                              ("independent", independent_oracle)):
            actual = oracle.expected_result(values, **kwargs)
            if actual != expected:
                issues.append(f"{label} reference differs for {case_id}")
    required = {
        "minimum-limit", "first-extension", "composite-square-small", "wheel-two",
        "early-prime", "multiple-wheel-growth", "prime-square-boundary", "hundred",
        "prime-limit-997", "maximum-limit", "below-domain", "above-domain",
        "trailing-word", "empty-frame", "null-input", "signed-minimum", "signed-maximum",
    }
    if seen != required:
        issues.append("fixture identifier set differs from the reviewed workload")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
