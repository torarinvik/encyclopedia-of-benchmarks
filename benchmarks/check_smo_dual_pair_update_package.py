"""Static inventory and fixture review for the SMO dual pair update package."""

from __future__ import annotations

import json
import math
from pathlib import Path

from smo_dual_pair_update_oracle import expected_output as primary_output
from smo_dual_pair_update_verifier_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/s/smo_dual_pair_update"
LANGUAGE_PATHS = {
    "c": ROOT / "c/s/smo_dual_pair_update.c",
    "c3": ROOT / "c3/s/smo_dual_pair_update.c3",
    "cpp": ROOT / "cpp/s/smo_dual_pair_update.cpp",
    "elisa": ROOT / "elisa/s/smo_dual_pair_update.elisa",
    "mojo": ROOT / "mojo/s/smo_dual_pair_update.mojo",
    "nim": ROOT / "nim/s/smo_dual_pair_update.nim",
    "odin": ROOT / "odin/s/smo_dual_pair_update.odin",
    "rust": ROOT / "rust/s/smo_dual_pair_update.rs",
    "v": ROOT / "v/s/smo_dual_pair_update.v",
    "zig": ROOT / "zig/s/smo_dual_pair_update.zig",
}


def _close(actual: object, expected: object, absolute: float, relative: float) -> bool:
    return (type(actual) in (int, float) and math.isfinite(float(actual))
            and abs(float(actual) - float(expected))
            <= absolute + relative * abs(float(expected)))


def _fixture_issues(case: dict, absolute: float, relative: float) -> list[str]:
    values = case.get("input_values")
    length = case.get("input_length")
    if not isinstance(values, list) or type(length) is not int:
        return [f"invalid fixture framing: {case.get('id', '<unnamed>')}"]
    capacity = case.get("output_capacity", 9)
    output_is_null = case.get("output_is_null", False)
    input_is_null = case.get("input_is_null", False)
    result, output = primary_output(values, capacity, output_is_null, input_is_null, length)
    other_result, other_output = independent_output(
        values, capacity, output_is_null, input_is_null, length)
    issues: list[str] = []
    case_id = case.get("id", "<unnamed>")
    expected = case.get("expected_output", [])
    if result != case.get("expected_result") or not isinstance(expected, list):
        issues.append(f"primary fixture result mismatch: {case_id}")
    elif len(expected) != len(output) or any(
            not _close(got, want, absolute, relative)
            for got, want in zip(expected, output)):
        issues.append(f"primary output disagrees with fixture: {case_id}")
    if other_result != result or len(other_output) != len(output):
        issues.append(f"independent oracle shape/result mismatch: {case_id}")
    elif any(not _close(a, b, absolute, relative)
             for a, b in zip(output, other_output)):
        issues.append(f"independent oracle numerical mismatch: {case_id}")
    return issues


def static_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    issues: list[str] = []
    if (workload.get("algorithm") != "smo_dual_pair_update"
            or workload.get("function_symbol") != "smo_dual_pair_update"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("pinned_source", {}).get("url")
            != "https://www.microsoft.com/en-us/research/publication/sequential-minimal-optimization-a-fast-algorithm-for-training-support-vector-machines/"):
        issues.append("algorithm identity or source metadata mismatch")
    contract = workload.get("contract", {})
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (contract.get("input_length") != "exactly 6+2*N+N*D"
            or contract.get("maximum_valid_input_length") != 46
            or contract.get("maximum_parseable_input_length") != 47
            or contract.get("maximum_output_elements") != 9
            or input_spec.get("maximum_valid_input_length") != 46
            or input_spec.get("maximum_parseable_input_length") != 47):
        issues.append("input or output bounds mismatch")
    if (output_spec.get("maximum_elements") != 9
            or output_spec.get("maximum_bytes") != 72
            or output_spec.get("success_result") != "N+1"
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("invalid_output_buffer_result") != -2):
        issues.append("float64 ABI output contract mismatch")
    measurement = workload.get("measurement", {})
    absolute = measurement.get("absolute_tolerance")
    relative = measurement.get("relative_tolerance")
    if (measurement.get("comparison_model") != "float64_slice_io_call"
            or absolute != 1e-12 or relative != 1e-12):
        issues.append("measurement tolerance mismatch")

    expected_case_ids = {
        "opposite_labels_clipped_at_C", "interior_pair_step",
        "zero_curvature_duplicate_features", "same_label_pair_step",
        "maximum_frame_zero_curvature_pair", "invalid_fractional_field",
        "invalid_infeasible_initial_alpha", "invalid_same_pair_index",
        "invalid_short_frame", "invalid_extra_frame_value",
    }
    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases} != expected_case_ids:
        issues.append("semantic fixture inventory mismatch")
    expected_abi_ids = {
        "null_input", "valid_input_null_output", "valid_input_short_capacity",
        "invalid_input_precedes_capacity_error",
    }
    abi_cases = workload.get("abi_cases")
    if not isinstance(abi_cases, list) or {case.get("id") for case in abi_cases} != expected_abi_ids:
        issues.append("ABI fixture inventory mismatch")
    for case in (*(cases if isinstance(cases, list) else []),
                 *(abi_cases if isinstance(abi_cases, list) else [])):
        if isinstance(case, dict):
            issues.extend(_fixture_issues(case, absolute, relative))
        else:
            issues.append("workload contains a non-object fixture")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
        elif "smo_dual_pair_update" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for filename in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package document: {filename}")
    for filename in ("smo_dual_pair_update_oracle.py",
                     "smo_dual_pair_update_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / filename).is_file():
            issues.append(f"missing oracle module: {filename}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
