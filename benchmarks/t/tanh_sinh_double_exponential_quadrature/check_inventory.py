"""Read-only static package inventory checks; this module is not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/t/tanh_sinh_double_exponential_quadrature.c",
    "c3": ROOT / "c3/t/tanh_sinh_double_exponential_quadrature.c3",
    "cpp": ROOT / "cpp/t/tanh_sinh_double_exponential_quadrature.cpp",
    "elisa": ROOT / "elisa/t/tanh_sinh_double_exponential_quadrature.elisa",
    "mojo": ROOT / "mojo/t/tanh_sinh_double_exponential_quadrature.mojo",
    "nim": ROOT / "nim/t/tanh_sinh_double_exponential_quadrature.nim",
    "odin": ROOT / "odin/t/tanh_sinh_double_exponential_quadrature.odin",
    "rust": ROOT / "rust/t/tanh_sinh_double_exponential_quadrature.rs",
    "v": ROOT / "v/t/tanh_sinh_double_exponential_quadrature.v",
    "zig": ROOT / "zig/t/tanh_sinh_double_exponential_quadrature.zig",
}
EXPECTED_CASES = {
    "constant_coarsest", "polynomial_x_squared", "two_endpoint_singularities",
    "right_endpoint_singularity", "maximum_grid", "invalid_function_id", "invalid_low_p",
    "invalid_high_p", "invalid_fractional_p", "invalid_short_frame", "invalid_max_trailing_word",
}
EXPECTED_ABI_CASES = {
    "null_input", "valid_input_null_output", "valid_input_zero_capacity",
    "invalid_input_precedes_output_error",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
                 "check_inventory.py", "__init__.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact {name}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "tanh_sinh_double_exponential_quadrature" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if language == "elisa" and ("view[f64]" not in source or "UnsafePointer" in source):
            issues.append("Elisa should use bounded views internally and no UnsafePointer")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package metadata: {error}"]
    expected_paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if (inventory.get("algorithm") != "tanh_sinh_double_exponential_quadrature"
            or set(inventory.get("native_paths", [])) != expected_paths):
        issues.append("inventory identity or ten native source paths are incorrect")
    if (workload.get("abi") != "float64_slice_io"
            or workload.get("input", {}).get("maximum_valid_input_length") != 2
            or workload.get("input", {}).get("maximum_parseable_input_length") != 3
            or workload.get("output", {}).get("maximum_elements") != 1
            or workload.get("workspace", {}).get("elements") != 1
            or workload.get("workspace", {}).get("bytes") != 8):
        issues.append("workload does not match the bounded float64 contract")
    for section, expected_ids in (("cases", EXPECTED_CASES), ("abi_cases", EXPECTED_ABI_CASES)):
        cases = workload.get(section, [])
        if {case.get("id") for case in cases if isinstance(case, dict)} != expected_ids:
            issues.append(f"{section} fixture identifiers differ from the reviewed set")
        for case in cases:
            if not isinstance(case, dict):
                continue
            values, length = case.get("input_values"), case.get("input_length")
            null = case.get("input_is_null", False)
            if (not isinstance(values, list) or type(length) is not int
                    or type(null) is not bool or (null and length != 0)
                    or (not null and length != len(values)) or length > 3):
                issues.append(f"invalid {section} framing for {case.get('id')}")
            result = case.get("expected_result")
            output = case.get("expected_output")
            if not isinstance(output, list) or len(output) != (1 if result == 1 else 0):
                issues.append(f"invalid {section} output size for {case.get('id')}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
