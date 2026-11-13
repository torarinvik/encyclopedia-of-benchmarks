"""Static source-inventory checks for the bounded Romberg package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks" / "r" / "romberg_integration"
SOURCES = {
    "c": ROOT / "c/r/romberg_integration.c",
    "c3": ROOT / "c3/r/romberg_integration.c3",
    "cpp": ROOT / "cpp/r/romberg_integration.cpp",
    "elisa": ROOT / "elisa/r/romberg_integration.elisa",
    "mojo": ROOT / "mojo/r/romberg_integration.mojo",
    "nim": ROOT / "nim/r/romberg_integration.nim",
    "odin": ROOT / "odin/r/romberg_integration.odin",
    "rust": ROOT / "rust/r/romberg_integration.rs",
    "v": ROOT / "v/r/romberg_integration.v",
    "zig": ROOT / "zig/r/romberg_integration.zig",
}
EXPECTED_CASES = {
    "exponential_symmetric_interval", "fifth_power_symmetric_interval",
    "fifth_power_unit_interval", "reciprocal_symmetric_interval", "cosine_zero_to_one",
    "exponential_short_interval", "equal_endpoints", "invalid_function_id",
    "invalid_fractional_field", "invalid_endpoint_below_range", "invalid_descending_interval",
    "invalid_low_level_count", "invalid_high_level_count", "invalid_short_frame",
    "invalid_extra_frame_value",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for path in (PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
                 ROOT / "benchmarks/romberg_integration_oracle.py",
                 ROOT / "benchmarks/romberg_integration_verifier_oracle.py"):
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    elisa_source = ""
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "romberg_integration" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if language == "elisa":
            elisa_source = source
    if elisa_source and ("view[f64]" not in elisa_source
                         or "UnsafePointer" in elisa_source or "*f64" in elisa_source):
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
            if (workload.get("algorithm") != "romberg_integration"
                    or workload.get("function_symbol") != "romberg_integration"
                    or workload.get("abi") != "float64_slice_io"
                    or workload.get("input", {}).get("maximum_valid_input_length") != 4
                    or workload.get("input", {}).get("maximum_parseable_input_length") != 5
                    or workload.get("output", {}).get("maximum_elements") != 1
                    or workload.get("workspace", {}).get("elements") != 1
                    or workload.get("workspace", {}).get("bytes") != 8):
                issues.append("workload metadata differs from the bounded float64_slice_io contract")
            if ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixture set")
            if not isinstance(workload.get("abi_cases"), list) or not workload["abi_cases"]:
                issues.append("workload is missing ABI boundary fixtures")

    primary = ROOT / "benchmarks/romberg_integration_oracle.py"
    independent = ROOT / "benchmarks/romberg_integration_verifier_oracle.py"
    if primary.is_file():
        source = primary.read_text(encoding="utf-8")
        for token in ("MAX_VALID_INPUT_LENGTH = 4", "MAX_PARSEABLE_INPUT_LENGTH = 5",
                      "def _romberg(", "current[order]"):
            if token not in source:
                issues.append(f"primary oracle lacks contract token {token!r}")
    if independent.is_file():
        source = independent.read_text(encoding="utf-8")
        if "_antiderivative_difference" not in source or "math.exp" not in source:
            issues.append("independent oracle must use closed-form antiderivative differences")
    return issues
