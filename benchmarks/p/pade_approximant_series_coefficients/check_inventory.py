"""Static package-path and workload-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/p/pade_approximant_series_coefficients.c",
    "c3": ROOT / "c3/p/pade_approximant_series_coefficients.c3",
    "cpp": ROOT / "cpp/p/pade_approximant_series_coefficients.cpp",
    "elisa": ROOT / "elisa/p/pade_approximant_series_coefficients.elisa",
    "mojo": ROOT / "mojo/p/pade_approximant_series_coefficients.mojo",
    "nim": ROOT / "nim/p/pade_approximant_series_coefficients.nim",
    "odin": ROOT / "odin/p/pade_approximant_series_coefficients.odin",
    "rust": ROOT / "rust/p/pade_approximant_series_coefficients.rs",
    "v": ROOT / "v/p/pade_approximant_series_coefficients.v",
    "zig": ROOT / "zig/p/pade_approximant_series_coefficients.zig",
}
EXPECTED_CASES = {
    "linear_pade_11", "geometric_series_pade_11", "nontrivial_pade_21",
    "nontrivial_pade_22", "maximum_degrees_and_output", "maximum_output_one_byte_short",
    "singular_denominator_system", "singular_after_capacity_check", "null_output",
    "invalid_degree_before_output_error", "invalid_q_above_p", "invalid_noncanonical_coefficient",
    "invalid_short_frame", "maximum_parseable_trailing_word", "null_input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for artifact in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
                     "check_inventory.py", "__init__.py"):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing artifact {artifact}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "pade_approximant_series_coefficients" not in source:
            issues.append(f"missing ABI symbol in {path.relative_to(ROOT)}")
        if language == "elisa" and ("view[i64]" not in source or "UnsafePointer" in source
                                    or "*i64" in source):
            issues.append("Elisa implementation should use bounded views internally")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package metadata JSON: {error}"]
    expected_paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if (inventory.get("algorithm") != "pade_approximant_series_coefficients"
            or set(inventory.get("native_paths", [])) != expected_paths):
        issues.append("inventory identity or language paths differ")
    if (workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != 11
            or workload.get("input", {}).get("maximum_parseable_length") != 12
            or workload.get("output", {}).get("maximum_bytes") != 96
            or workload.get("workspace", {}).get("bytes") != 256):
        issues.append("workload bounds differ from the bounded package contract")
    cases = workload.get("cases", [])
    if {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASES:
        issues.append("workload case IDs differ from the reviewed set")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        if (not isinstance(values, list) or type(length) is not int
                or (not case.get("input_is_null", False) and length != len(values))
                or length > 12):
            issues.append(f"invalid fixture framing for {case.get('id')}")
            continue
        expected_hex = case.get("expected_output_hex")
        if not isinstance(expected_hex, str) or len(expected_hex) != (case.get("expected_result", 0) if case.get("expected_result", 0) >= 0 else 0) * 2:
            issues.append(f"fixture output byte length differs for {case.get('id')}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
