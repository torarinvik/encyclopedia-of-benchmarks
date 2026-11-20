"""Static package and fixture inventory review; never runs language ports."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "maximum_sum_contiguous_submatrix"
LANGUAGE_PATHS = {
    "c": ROOT / "c/m/maximum_sum_contiguous_submatrix.c",
    "c3": ROOT / "c3/m/maximum_sum_contiguous_submatrix.c3",
    "cpp": ROOT / "cpp/m/maximum_sum_contiguous_submatrix.cpp",
    "elisa": ROOT / "elisa/m/maximum_sum_contiguous_submatrix.elisa",
    "mojo": ROOT / "mojo/m/maximum_sum_contiguous_submatrix.mojo",
    "nim": ROOT / "nim/m/maximum_sum_contiguous_submatrix.nim",
    "odin": ROOT / "odin/m/maximum_sum_contiguous_submatrix.odin",
    "rust": ROOT / "rust/m/maximum_sum_contiguous_submatrix.rs",
    "v": ROOT / "v/m/maximum_sum_contiguous_submatrix.v",
    "zig": ROOT / "zig/m/maximum_sum_contiguous_submatrix.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("rows_range") != [1, 8]
            or input_spec.get("columns_range") != [1, 8]
            or input_spec.get("maximum_valid_length") != 66
            or input_spec.get("maximum_parseable_length") != 67):
        issues.append("input bound mismatch")
    if output_spec.get("maximum_bytes") != 8 or workload.get("workspace", {}).get("bytes") != 1024:
        issues.append("output or workspace bound mismatch")
    profiles = workload.get("measurement", {}).get("profiles", [])
    if not any(profile.get("input_values", [])[:2] == [8, 8]
               and profile.get("output_bytes") == 8 for profile in profiles):
        issues.append("missing maximum-dimensions profile")
    for case in workload.get("cases", []):
        name = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"invalid fixture shape: {name}")
            continue
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"invalid output hex: {name}")
            continue
        expected = case.get("expected_result")
        if expected in (-1, -2) and payload:
            issues.append(f"error fixture writes output: {name}")
        elif expected == 8 and len(payload) != 8:
            issues.append(f"success byte count mismatch: {name}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file {filename}")
    return issues
