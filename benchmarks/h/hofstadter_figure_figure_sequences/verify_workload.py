"""Static workload/inventory review; does not execute language ports."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "hofstadter_figure_figure_sequences"
LANGUAGE_PATHS = {
    "c": ROOT / "c/h/hofstadter_figure_figure_sequences.c",
    "c3": ROOT / "c3/h/hofstadter_figure_figure_sequences.c3",
    "cpp": ROOT / "cpp/h/hofstadter_figure_figure_sequences.cpp",
    "elisa": ROOT / "elisa/h/hofstadter_figure_figure_sequences.elisa",
    "mojo": ROOT / "mojo/h/hofstadter_figure_figure_sequences.mojo",
    "nim": ROOT / "nim/h/hofstadter_figure_figure_sequences.nim",
    "odin": ROOT / "odin/h/hofstadter_figure_figure_sequences.odin",
    "rust": ROOT / "rust/h/hofstadter_figure_figure_sequences.rs",
    "v": ROOT / "v/h/hofstadter_figure_figure_sequences.v",
    "zig": ROOT / "zig/h/hofstadter_figure_figure_sequences.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    bounds = workload.get("input", {})
    if (bounds.get("term_count_range") != [1, 64]
            or bounds.get("maximum_valid_length") != 1
            or bounds.get("maximum_parseable_length") != 2):
        issues.append("input bound mismatch")
    if (workload.get("output", {}).get("maximum_bytes") != 1032
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("output or workspace bound mismatch")
    profiles = workload.get("measurement", {}).get("profiles", [])
    if not any(profile.get("input_values") == [64] and profile.get("output_bytes") == 1032
               for profile in profiles):
        issues.append("missing maximum-output profile")
    for case in workload.get("cases", []):
        name = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        length = case.get("input_length", len(values))
        if not isinstance(values, list) or not isinstance(length, int):
            issues.append(f"invalid fixture shape: {name}")
            continue
        if not case.get("input_is_null", False) and length != len(values):
            issues.append(f"fixture input length mismatch: {name}")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"invalid output hex: {name}")
            continue
        expected = case.get("expected_result")
        if not isinstance(expected, int):
            issues.append(f"missing expected result: {name}")
        elif expected in (-1, -2) and payload:
            issues.append(f"error fixture writes output: {name}")
        elif expected >= 0 and (expected != len(payload) or expected > 1032):
            issues.append(f"success byte count mismatch: {name}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file {filename}")
    return issues
