"""Source-local agreement helper for pinned fixtures; not run during drafting."""

from __future__ import annotations

import json
import math
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
    if (workload.get("algorithm") != "tanh_sinh_double_exponential_quadrature"
            or workload.get("function_symbol") != "tanh_sinh_double_exponential_quadrature"
            or workload.get("abi") != "float64_slice_io"):
        issues.append("workload identity or ABI differs from the package")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("maximum_elements") != primary_oracle.MAX_OUTPUT_ELEMENTS
            or output_spec.get("absolute_tolerance") != primary_oracle.ABSOLUTE_TOLERANCE
            or output_spec.get("relative_tolerance") != primary_oracle.RELATIVE_TOLERANCE):
        issues.append("workload bounds or tolerances differ from the primary reference")
    if (workload.get("workspace", {}).get("elements") != primary_oracle.WORKSPACE_ELEMENTS
            or workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES):
        issues.append("workspace accounting differs from the package bound")

    for section in ("cases", "abi_cases"):
        fixtures = workload.get(section)
        if not isinstance(fixtures, list):
            issues.append(f"{section} must be a list")
            continue
        for case in fixtures:
            if not isinstance(case, dict):
                issues.append(f"{section} contains a non-object fixture")
                continue
            case_id = case.get("id", "<missing>")
            values = case.get("input_values")
            length = case.get("input_length")
            is_null = case.get("input_is_null", False)
            if (not isinstance(values, list) or type(length) is not int
                    or type(is_null) is not bool
                    or (not is_null and length != len(values))
                    or (is_null and length != 0)):
                issues.append(f"invalid input frame in {case_id}")
                continue
            kwargs = {
                "input_length": length,
                "input_is_null": is_null,
                "output_is_null": case.get("output_is_null", False),
                "capacity": case.get("output_capacity", 1),
            }
            expected_result = case.get("expected_result")
            expected_values = case.get("expected_output")
            if not isinstance(expected_values, list):
                issues.append(f"expected output must be a list in {case_id}")
                continue
            for label, oracle in (("primary", primary_oracle),
                                  ("independent", independent_oracle)):
                result, actual = oracle.expected_output(values, **kwargs)
                if result != expected_result or len(actual) != len(expected_values):
                    issues.append(f"{label} status/output length differs for {case_id}")
                    continue
                if any(not math.isclose(value, float(want),
                                        rel_tol=primary_oracle.RELATIVE_TOLERANCE,
                                        abs_tol=primary_oracle.ABSOLUTE_TOLERANCE)
                       for value, want in zip(actual, expected_values)):
                    issues.append(f"{label} output differs for {case_id}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
