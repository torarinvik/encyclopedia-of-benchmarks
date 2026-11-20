"""Package-local static fixture/reference consistency checks."""

from __future__ import annotations

import json
import math
from pathlib import Path

from smo_deterministic_training_oracle import expected_output as primary_output
from smo_deterministic_training_verifier_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent
ABS_TOL = 1e-12
REL_TOL = 1e-12


def _matches(actual, expected) -> bool:
    if not isinstance(expected, (list, tuple)) or len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        if not math.isfinite(float(got)) or abs(float(got) - float(want)) > ABS_TOL + REL_TOL * abs(float(want)):
            return False
    return True


def workload_issues() -> tuple[str, ...]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    expected_cases = {
        "separable_pair_converged",
        "zero_curvature_duplicate_vectors",
        "pass_cap_reports_incomplete_trace",
        "maximum_zero_feature_plateau",
        "invalid_fractional_parameter",
        "invalid_single_class",
        "invalid_extra_input_value",
    }
    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases} != expected_cases:
        return ("workload fixture IDs differ from the pinned set",)
    for case in [*cases, *workload.get("abi_cases", [])]:
        args = (
            case.get("input_values"),
            case.get("output_capacity", 12),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        primary_result, primary_values = primary_output(*args)
        independent_result, independent_values = independent_output(*args)
        if primary_result != case.get("expected_result"):
            issues.append(f"{case.get('id')}: pinned result differs from primary reference")
        if independent_result != primary_result:
            issues.append(f"{case.get('id')}: references disagree on result code")
        expected = case.get("expected_output")
        if not _matches(primary_values, expected):
            issues.append(f"{case.get('id')}: pinned values differ from primary reference")
        if not _matches(independent_values, expected):
            issues.append(f"{case.get('id')}: pinned values differ from independent reference")
        if not _matches(primary_values, independent_values):
            issues.append(f"{case.get('id')}: references disagree on output")
    return tuple(issues)
