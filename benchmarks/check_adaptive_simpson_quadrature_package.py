"""Static inventory and fixture review for adaptive Simpson quadrature."""

from __future__ import annotations

import json
import math
from pathlib import Path

from adaptive_simpson_quadrature_oracle import expected_output as primary_output
from adaptive_simpson_quadrature_verifier_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/a/adaptive_simpson_quadrature"
LANGUAGE_PATHS = {
    "c": ROOT / "c/a/adaptive_simpson_quadrature.c",
    "c3": ROOT / "c3/a/adaptive_simpson_quadrature.c3",
    "cpp": ROOT / "cpp/a/adaptive_simpson_quadrature.cpp",
    "elisa": ROOT / "elisa/a/adaptive_simpson_quadrature.elisa",
    "mojo": ROOT / "mojo/a/adaptive_simpson_quadrature.mojo",
    "nim": ROOT / "nim/a/adaptive_simpson_quadrature.nim",
    "odin": ROOT / "odin/a/adaptive_simpson_quadrature.odin",
    "rust": ROOT / "rust/a/adaptive_simpson_quadrature.rs",
    "v": ROOT / "v/a/adaptive_simpson_quadrature.v",
    "zig": ROOT / "zig/a/adaptive_simpson_quadrature.zig",
}


def _fixture_issues(case: dict, absolute: float, relative: float) -> list[str]:
    issues: list[str] = []
    values = case.get("input_values")
    input_length = case.get("input_length")
    capacity = case.get("output_capacity", 1)
    output_is_null = case.get("output_is_null", False)
    input_is_null = case.get("input_is_null", False)
    if not isinstance(values, list) or type(input_length) is not int:
        return [f"invalid fixture framing: {case.get('id', '<unnamed>')}"]
    result, output = primary_output(values, capacity, output_is_null, input_is_null, input_length)
    check_result, check_output = independent_output(
        values, capacity, output_is_null, input_is_null, input_length)
    case_id = case.get("id", "<unnamed>")
    if result != case.get("expected_result") or len(output) != len(case.get("expected_output", [])):
        issues.append(f"primary fixture mismatch: {case_id}")
    raw_expected = case.get("expected_output", [])
    if (not isinstance(raw_expected, list) or len(raw_expected) != len(output)
            or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                   or abs(float(actual) - reference) > absolute + relative * abs(reference)
                   for actual, reference in zip(raw_expected, output))):
        issues.append(f"primary output disagrees with fixture: {case_id}")
    if check_result != result or len(check_output) != len(output):
        issues.append(f"independent oracle shape/result mismatch: {case_id}")
    elif any(abs(a - b) > absolute + relative * abs(b) for a, b in zip(output, check_output)):
        issues.append(f"independent oracle numerical mismatch: {case_id}")
    return issues


def static_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    issues: list[str] = []
    if (workload.get("algorithm") != "adaptive_simpson_quadrature"
            or workload.get("function_symbol") != "adaptive_simpson_quadrature"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("pinned_source", {}).get("url")
            != "https://en.oi-wiki.org/math/integral/#245"
            or workload.get("pinned_source", {}).get("license")
            != "CC BY-SA 4.0 and SATA"):
        issues.append("algorithm identity or ABI mismatch")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("exact_length") != 5
            or input_spec.get("maximum_valid_input_length") != 5
            or input_spec.get("maximum_parseable_input_length") != 6
            or input_spec.get("tolerance_exponent_range") != [7, 8]
            or input_spec.get("maximum_refinement_depth_range") != [8, 12]
            or input_spec.get("endpoint_micro_range") != [-2000000, 2000000]):
        issues.append("input bounds mismatch")
    if (output_spec.get("maximum_elements") != 1
            or output_spec.get("maximum_bytes") != 8
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("invalid_output_buffer_result") != -2):
        issues.append("output ABI mismatch")
    measurement = workload.get("measurement", {})
    absolute = measurement.get("absolute_tolerance")
    relative = measurement.get("relative_tolerance")
    if (measurement.get("comparison_model") != "float64_slice_io_call"
            or absolute != 1e-7 or relative != 1e-7):
        issues.append("measurement contract mismatch")

    expected_case_ids = {
        "quartic_unit_interval", "quartic_symmetric_interval", "quartic_negative_interval",
        "sine_unit_interval", "sine_negative_to_zero", "reciprocal_symmetric_interval",
        "reciprocal_full_profile_interval", "equal_endpoint_interval", "invalid_function_id",
        "invalid_fractional_field", "invalid_endpoint_below_domain", "invalid_descending_interval",
        "invalid_tolerance_exponent", "invalid_tolerance_exponent_above_range",
        "invalid_refinement_depth", "invalid_short_frame", "invalid_extra_frame_value",
    }
    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases} != expected_case_ids:
        issues.append("semantic fixture inventory mismatch")
    expected_abi_ids = {
        "null_input", "valid_input_null_output", "valid_input_zero_capacity",
        "invalid_input_precedes_output_error",
    }
    abi_cases = workload.get("abi_cases")
    if not isinstance(abi_cases, list) or {case.get("id") for case in abi_cases} != expected_abi_ids:
        issues.append("ABI fixture inventory mismatch")

    semantic_cases = cases if isinstance(cases, list) else []
    abi_fixtures = abi_cases if isinstance(abi_cases, list) else []
    for case in (*semantic_cases, *abi_fixtures):
        if isinstance(case, dict):
            issues.extend(_fixture_issues(case, absolute, relative))
        else:
            issues.append("workload contains a non-object fixture")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
        elif "adaptive_simpson_quadrature" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for filename in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package document: {filename}")
    for filename in ("adaptive_simpson_quadrature_oracle.py",
                     "adaptive_simpson_quadrature_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / filename).is_file():
            issues.append(f"missing oracle module: {filename}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
