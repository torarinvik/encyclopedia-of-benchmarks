"""Static workload and dual-reference checker; intentionally not run."""

from __future__ import annotations

import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
sys.path.insert(0, str(REPOSITORY / "benchmarks"))

from independent_oracle import expected_result as independent_expected_result
from primary_oracle import (
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected_result,
)


def workload_issues(workload: dict | None = None) -> list[str]:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if workload.get("algorithm") != "quantum_spectral_energy_expectation":
        issues.append("algorithm id differs from package name")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("abi") != "i64_array_float64"):
        issues.append("workload bounds or ABI differ from the package contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no case list"]
    ids: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload case is not an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in ids:
            issues.append(f"missing or duplicate case id: {case_id!r}")
            continue
        ids.add(case_id)
        values = case.get("input_values")
        expected = case.get("expected_result")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(input_length) is not int or input_length != len(values)
                or input_is_null and values
                or not input_is_null and len(values) > MAX_PARSEABLE_INPUT_LENGTH
                or type(expected) not in (int, float) or not math.isfinite(expected)):
            issues.append(f"malformed frame or result in case {case_id}")
            continue
        primary = primary_expected_result(
            values, input_is_null=input_is_null, input_length=input_length)
        independent = independent_expected_result(
            values, input_is_null=input_is_null, input_length=input_length)
        if not math.isclose(primary, independent, rel_tol=1e-10, abs_tol=1e-9):
            issues.append(f"primary and independent references disagree in {case_id}")
        if not math.isclose(expected, independent, rel_tol=1e-10, abs_tol=1e-9):
            issues.append(f"fixture result differs from independent reference in {case_id}")
    return issues


if __name__ == "__main__":
    found = workload_issues()
    if found:
        raise SystemExit("\n".join(found))
