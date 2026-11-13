"""Static source-inventory checks for the Dormand–Prince adaptive ODE package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks" / "d" / "dormand_prince_54_adaptive_ode"
SOURCES = {
    "c": ROOT / "c/d/dormand_prince_54_adaptive_ode.c",
    "c3": ROOT / "c3/d/dormand_prince_54_adaptive_ode.c3",
    "cpp": ROOT / "cpp/d/dormand_prince_54_adaptive_ode.cpp",
    "elisa": ROOT / "elisa/d/dormand_prince_54_adaptive_ode.elisa",
    "mojo": ROOT / "mojo/d/dormand_prince_54_adaptive_ode.mojo",
    "nim": ROOT / "nim/d/dormand_prince_54_adaptive_ode.nim",
    "odin": ROOT / "odin/d/dormand_prince_54_adaptive_ode.odin",
    "rust": ROOT / "rust/d/dormand_prince_54_adaptive_ode.rs",
    "v": ROOT / "v/d/dormand_prince_54_adaptive_ode.v",
    "zig": ROOT / "zig/d/dormand_prince_54_adaptive_ode.zig",
}
EXPECTED_CASES = {
    "exponential_growth", "negative_exponential_growth", "affine_forcing",
    "sine_forcing", "constant_derivative", "symmetric_sine_cancellation",
    "affine_forcing_negative_interval", "adaptive_rejection_and_growth",
    "invalid_function_id", "invalid_fractional_field", "invalid_initial_state",
    "invalid_endpoint_outside_range", "invalid_nonincreasing_interval",
    "invalid_loose_tolerance", "invalid_tight_tolerance", "invalid_low_attempt_limit",
    "invalid_high_attempt_limit", "invalid_short_frame", "invalid_extra_frame_value",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for path in (PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
                 PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py"):
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    contents: dict[str, str] = {}
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        contents[language] = source
        if "dormand_prince_54_adaptive_ode" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
    elisa = contents.get("elisa", "")
    if elisa and ("view[f64]" not in elisa or "UnsafePointer" in elisa or "*f64" in elisa):
        issues.append("Elisa implementation must use safe views internally and ABI references only")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            cases = workload.get("cases")
            ids = ({case.get("id") for case in cases}
                   if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                   else set())
            if (workload.get("algorithm") != "dormand_prince_54_adaptive_ode"
                    or workload.get("function_symbol") != "dormand_prince_54_adaptive_ode"
                    or workload.get("abi") != "float64_slice_io"
                    or workload.get("input", {}).get("maximum_valid_input_length") != 6
                    or workload.get("input", {}).get("maximum_parseable_input_length") != 7
                    or workload.get("input", {}).get("tolerance_exponent_range") != [8, 9]
                    or workload.get("output", {}).get("maximum_elements") != 1
                    or workload.get("output", {}).get("absolute_tolerance") != 2e-7
                    or workload.get("output", {}).get("relative_tolerance") != 2e-7
                    or workload.get("workspace", {}).get("elements") != 1
                    or workload.get("workspace", {}).get("bytes") != 8):
                issues.append("workload metadata differs from the bounded float64_slice_io contract")
            if ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixture set")
            abi_cases = workload.get("abi_cases")
            if (not isinstance(abi_cases, list)
                    or {case.get("id") for case in abi_cases if isinstance(case, dict)} != {
                        "null_input", "valid_input_null_output", "valid_input_zero_capacity",
                        "invalid_input_precedes_output_error"}):
                issues.append("workload ABI fixture inventory differs from the reviewed boundary set")

    primary_path = PACKAGE / "primary_oracle.py"
    if primary_path.is_file():
        source = primary_path.read_text(encoding="utf-8")
        for token in ("MAX_VALID_INPUT_LENGTH = 6", "MAX_PARSEABLE_INPUT_LENGTH = 7",
                      "MIN_TOLERANCE_EXPONENT = 8", "def _trial(", "def _integrate(",
                      "k1 = k7", "NUMERICAL_FAILURE = -3"):
            if token not in source:
                issues.append(f"primary oracle missing adaptive-solver token {token!r}")
    independent_path = PACKAGE / "independent_oracle.py"
    if independent_path.is_file():
        source = independent_path.read_text(encoding="utf-8")
        for token in ("math.exp", "math.cos", "_finite_number", "8 <= tolerance_exponent <= 9"):
            if token not in source:
                issues.append(f"independent oracle missing closed-form/validation token {token!r}")
    return issues
