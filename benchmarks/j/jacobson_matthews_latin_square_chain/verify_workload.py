"""Static workload and inventory checks; never launches a language port."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "jacobson_matthews_latin_square_chain"
LANGUAGE_PATHS = {
    "c": ROOT / "c/j/jacobson_matthews_latin_square_chain.c",
    "c3": ROOT / "c3/j/jacobson_matthews_latin_square_chain.c3",
    "cpp": ROOT / "cpp/j/jacobson_matthews_latin_square_chain.cpp",
    "elisa": ROOT / "elisa/j/jacobson_matthews_latin_square_chain.elisa",
    "mojo": ROOT / "mojo/j/jacobson_matthews_latin_square_chain.mojo",
    "nim": ROOT / "nim/j/jacobson_matthews_latin_square_chain.nim",
    "odin": ROOT / "odin/j/jacobson_matthews_latin_square_chain.odin",
    "rust": ROOT / "rust/j/jacobson_matthews_latin_square_chain.rs",
    "v": ROOT / "v/j/jacobson_matthews_latin_square_chain.v",
    "zig": ROOT / "zig/j/jacobson_matthews_latin_square_chain.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected exported symbol or ABI")
    if (workload.get("input", {}).get("order_range") != [2, 4]
            or workload.get("input", {}).get("step_count_range") != [0, 12]
            or workload.get("input", {}).get("maximum_valid_length") != 14):
        issues.append("input bounds mismatch")
    if (workload.get("output", {}).get("maximum_bytes") != 528
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("output or workspace bounds mismatch")
    for case in workload.get("cases", []):
        name = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        length = case.get("input_length", len(values))
        if not isinstance(values, list) or not isinstance(length, int):
            issues.append(f"invalid fixture shape: {name}")
            continue
        if not case.get("input_is_null", False) and length != len(values):
            issues.append(f"fixture length mismatch: {name}")
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
        elif expected >= 0 and (expected != len(payload) or expected > 528):
            issues.append(f"success byte count mismatch: {name}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    return issues
