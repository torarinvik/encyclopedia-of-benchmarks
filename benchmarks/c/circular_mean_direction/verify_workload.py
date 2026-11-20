"""Static workload/oracle checks for circular mean direction."""

from __future__ import annotations

import json
import math
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import expected_output as primary

PACKAGE = Path(__file__).resolve().parent
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
EXPECTED_CASES = {
    "single-radian-angle", "average-across-wrap-boundary",
    "single-positive-pi-normalizes-negative", "multi-turn-angle",
    "near-zero-resultant-below-cutoff", "near-zero-resultant-above-cutoff",
    "uniform-cardinal-directions-undefined", "empty-input-frame", "zero-count",
    "fractional-count", "count-length-mismatch", "trailing-value",
    "angle-outside-bound",
}
EXPECTED_ABI_CASES = {
    "null-input-pointer", "valid-input-null-output", "valid-input-zero-capacity",
    "invalid-input-precedes-output-error",
}


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "circular_mean_direction"
            or workload.get("function_symbol") != "circular_mean_direction"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("input", {}).get("maximum_valid_input_length") != 65
            or workload.get("input", {}).get("maximum_parseable_input_length") != 66
            or workload.get("output", {}).get("maximum_elements") != 1
            or workload.get("measurement", {}).get("absolute_tolerance") != 1e-12
            or workload.get("measurement", {}).get("relative_tolerance") != 1e-12):
        issues.append("workload bounds, ABI, or measurement metadata differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases} != EXPECTED_CASES:
        issues.append("workload fixture set differs from the reviewed case inventory")
        return issues
    abi_cases = workload.get("abi_cases")
    if (not isinstance(abi_cases, list)
            or {case.get("id") for case in abi_cases} != EXPECTED_ABI_CASES):
        issues.append("workload ABI fixture set differs from the reviewed boundary inventory")
        return issues
    for case in [*cases, *abi_cases]:
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"{case.get('id')}: input_values must be a list")
            continue
        args = (values, case.get("output_capacity", 1),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
        expected = primary(*args)
        independent_expected = independent(*args)
        if expected != independent_expected:
            # The two numeric methods may differ within the suite's float tolerance.
            status_a, output_a = expected
            status_b, output_b = independent_expected
            if (status_a != status_b or len(output_a) != len(output_b)
                    or any(abs(a - b) > 1e-12 for a, b in zip(output_a, output_b))):
                issues.append(f"{case.get('id')}: primary and independent references disagree")
                continue
        result, output = expected
        pinned_output = case.get("expected_output")
        if (case.get("expected_result") != result or not isinstance(pinned_output, list)
                or len(pinned_output) != len(output)
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       or abs(float(value) - target) > 1e-12
                       for value, target in zip(pinned_output, output))):
            issues.append(f"{case.get('id')}: pinned expectation differs from the references")
    return issues
