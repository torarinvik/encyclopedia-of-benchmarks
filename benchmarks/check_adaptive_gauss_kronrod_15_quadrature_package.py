"""Static inventory and fixture review for adaptive Gauss-Kronrod quadrature."""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "benchmarks"))

from adaptive_gauss_kronrod_15_quadrature_oracle import expected_output as primary_output
from adaptive_gauss_kronrod_15_quadrature_verifier_oracle import expected_output as independent_output

PACKAGE = ROOT / "benchmarks/a/adaptive_gauss_kronrod_15_quadrature"
SYMBOL = "adaptive_gauss_kronrod_15_quadrature"
LANGUAGE_PATHS = {
    "c": ROOT / "c/a/adaptive_gauss_kronrod_15_quadrature.c",
    "c3": ROOT / "c3/a/adaptive_gauss_kronrod_15_quadrature.c3",
    "cpp": ROOT / "cpp/a/adaptive_gauss_kronrod_15_quadrature.cpp",
    "elisa": ROOT / "elisa/a/adaptive_gauss_kronrod_15_quadrature.elisa",
    "mojo": ROOT / "mojo/a/adaptive_gauss_kronrod_15_quadrature.mojo",
    "nim": ROOT / "nim/a/adaptive_gauss_kronrod_15_quadrature.nim",
    "odin": ROOT / "odin/a/adaptive_gauss_kronrod_15_quadrature.odin",
    "rust": ROOT / "rust/a/adaptive_gauss_kronrod_15_quadrature.rs",
    "v": ROOT / "v/a/adaptive_gauss_kronrod_15_quadrature.v",
    "zig": ROOT / "zig/a/adaptive_gauss_kronrod_15_quadrature.zig",
}
ABSOLUTE = 2e-7
RELATIVE = 2e-7


def _fixture_issues(case: dict) -> list[str]:
    case_id = case.get("id", "<unnamed>")
    values = case.get("input_values")
    length = case.get("input_length")
    if not isinstance(values, list) or type(length) is not int:
        return [f"invalid fixture framing: {case_id}"]
    capacity = case.get("output_capacity", 1)
    output_null = case.get("output_is_null", False)
    input_null = case.get("input_is_null", False)
    primary_result, primary_values = primary_output(
        values, capacity, output_null, input_null, length)
    independent_result, independent_values = independent_output(
        values, capacity, output_null, input_null, length)
    expected_result = case.get("expected_result")
    expected_values = case.get("expected_output", [])
    issues: list[str] = []
    if primary_result != expected_result or independent_result != expected_result:
        issues.append(f"oracle result differs from fixture: {case_id}")
    if (not isinstance(expected_values, list)
            or len(primary_values) != len(expected_values)
            or len(independent_values) != len(expected_values)):
        issues.append(f"oracle output shape differs from fixture: {case_id}")
        return issues
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           or abs(float(value) - expected) > ABSOLUTE + RELATIVE * abs(expected)
           for value, expected in zip(expected_values, primary_values)):
        issues.append(f"primary oracle differs from fixture: {case_id}")
    if any(abs(actual - expected) > ABSOLUTE + RELATIVE * abs(expected)
           for actual, expected in zip(independent_values, expected_values)):
        issues.append(f"independent oracle differs from fixture: {case_id}")
    if any(abs(a - b) > ABSOLUTE + RELATIVE * abs(b)
           for a, b in zip(primary_values, independent_values)):
        issues.append(f"oracles disagree: {case_id}")
    return issues


def static_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    issues: list[str] = []
    source = workload.get("pinned_source", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "float64_slice_io"
            or source.get("url") != "https://www.gnu.org/software/gsl/doc/html/integration.html"):
        issues.append("algorithm identity, source, or ABI mismatch")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (input_spec.get("exact_length") != 5
            or input_spec.get("maximum_valid_input_length") != 5
            or input_spec.get("maximum_parseable_input_length") != 6
            or input_spec.get("function_id_range") != [0, 3]
            or input_spec.get("endpoint_micro_range") != [-1000000, 1000000]
            or input_spec.get("tolerance_exponent_range") != [6, 8]
            or input_spec.get("interval_limit_range") != [1, 16]):
        issues.append("input bounds mismatch")
    if (output_spec.get("maximum_elements") != 1
            or output_spec.get("maximum_bytes") != 8
            or output_spec.get("success_result") != 1
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("invalid_output_buffer_result") != -2
            or output_spec.get("numerical_failure_result") != -3
            or workspace.get("elements") != 1 or workspace.get("bytes") != 8):
        issues.append("output or workspace ABI mismatch")
    measurement = workload.get("measurement", {})
    if (measurement.get("comparison_model") != "float64_slice_io_call"
            or measurement.get("absolute_tolerance") != ABSOLUTE
            or measurement.get("relative_tolerance") != RELATIVE):
        issues.append("measurement tolerance mismatch")
    expected_case_ids = {
        "exponential_unit_interval", "sine_unit_interval", "rational_symmetric_interval",
        "fourteenth_power_symmetric_interval", "exponential_negative_interval",
        "equal_endpoints", "interval_cap_exhausted", "invalid_function_id",
        "invalid_fractional_field", "invalid_endpoint_below_domain",
        "invalid_descending_interval", "invalid_tolerance_exponent",
        "invalid_interval_limit", "invalid_short_frame", "invalid_extra_frame_value",
    }
    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases} != expected_case_ids:
        issues.append("semantic fixture inventory mismatch")
        cases = cases if isinstance(cases, list) else []
    expected_abi_ids = {
        "null_input", "valid_input_null_output", "valid_input_zero_capacity",
        "invalid_input_precedes_output_error", "valid_input_precedes_interval_exhaustion",
    }
    abi_cases = workload.get("abi_cases")
    if not isinstance(abi_cases, list) or {case.get("id") for case in abi_cases} != expected_abi_ids:
        issues.append("ABI fixture inventory mismatch")
        abi_cases = abi_cases if isinstance(abi_cases, list) else []
    for case in (*cases, *abi_cases):
        if isinstance(case, dict):
            issues.extend(_fixture_issues(case))
        else:
            issues.append("workload contains a non-object fixture")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for filename in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package document: {filename}")
    for filename in ("adaptive_gauss_kronrod_15_quadrature_oracle.py",
                     "adaptive_gauss_kronrod_15_quadrature_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / filename).is_file():
            issues.append(f"missing oracle module: {filename}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
