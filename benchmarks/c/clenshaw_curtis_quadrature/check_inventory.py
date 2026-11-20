"""Static inventory checks for the Clenshaw–Curtis package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/c/clenshaw_curtis_quadrature.c",
    "c3": ROOT / "c3/c/clenshaw_curtis_quadrature.c3",
    "cpp": ROOT / "cpp/c/clenshaw_curtis_quadrature.cpp",
    "elisa": ROOT / "elisa/c/clenshaw_curtis_quadrature.elisa",
    "mojo": ROOT / "mojo/c/clenshaw_curtis_quadrature.mojo",
    "nim": ROOT / "nim/c/clenshaw_curtis_quadrature.nim",
    "odin": ROOT / "odin/c/clenshaw_curtis_quadrature.odin",
    "rust": ROOT / "rust/c/clenshaw_curtis_quadrature.rs",
    "v": ROOT / "v/c/clenshaw_curtis_quadrature.v",
    "zig": ROOT / "zig/c/clenshaw_curtis_quadrature.zig",
}
EXPECTED_CASES = {
    "constant_n2", "linear_n2", "quadratic_n2", "quartic_n4", "constant_max_n16",
    "invalid_odd_n", "invalid_low_n", "invalid_high_n", "invalid_sample_bound",
    "invalid_short_frame", "invalid_max_trailing_word",
}
EXPECTED_ABI_CASES = {
    "null_input", "valid_input_null_output", "valid_input_zero_capacity",
    "invalid_input_precedes_output_error",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "__init__.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact {filename}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "clenshaw_curtis_quadrature" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the ABI symbol")
        if language == "elisa" and ("view[f64]" not in source or "UnsafePointer" in source
                                    or "*f64" in source):
            issues.append("Elisa internals should use bounded views, with pointers confined to the ABI")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package metadata JSON: {error}"]
    expected_paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if (inventory.get("algorithm") != "clenshaw_curtis_quadrature"
            or set(inventory.get("native_paths", [])) != expected_paths
            or inventory.get("suite_integration")
            != "benchmarks/run_float64_slice_io.py and benchmarks/verify_float64_slice_io.py"):
        issues.append("inventory identity, suite integration, or ten-language path count is wrong")
    if (workload.get("abi") != "float64_slice_io"
            or workload.get("input", {}).get("maximum_valid_input_length") != 18
            or workload.get("input", {}).get("maximum_parseable_input_length") != 19
            or workload.get("output", {}).get("maximum_elements") != 1
            or workload.get("workspace", {}).get("elements") != 1
            or workload.get("workspace", {}).get("bytes") != 8):
        issues.append("workload does not match the bounded ABI contract")
    cases = workload.get("cases", [])
    abi_cases = workload.get("abi_cases", [])
    if {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASES:
        issues.append("workload fixture IDs differ from the reviewed set")
    if {case.get("id") for case in abi_cases if isinstance(case, dict)} != EXPECTED_ABI_CASES:
        issues.append("ABI fixture IDs differ from the reviewed set")
    for section, items in (("cases", cases), ("abi_cases", abi_cases)):
        for case in items:
            if not isinstance(case, dict):
                continue
            values = case.get("input_values")
            length = case.get("input_length")
            if (not isinstance(values, list) or type(length) is not int
                    or (not case.get("input_is_null", False) and length != len(values))):
                issues.append(f"{section} input framing is invalid for {case.get('id')}")
                continue
            expected = case.get("expected_output")
            result = case.get("expected_result")
            if not isinstance(expected, list) or len(expected) != (1 if result == 1 else 0):
                issues.append(f"{section} output length is invalid for {case.get('id')}")
            if length > 19:
                issues.append(f"{section} exceeds parseable frame bound for {case.get('id')}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
