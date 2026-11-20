"""Static package metadata and inventory review; never launches language ports."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "glushkov_bit_parallel_regex_search"
LANGUAGE_PATHS = {
    "c": ROOT / "c/g/glushkov_bit_parallel_regex_search.c",
    "c3": ROOT / "c3/g/glushkov_bit_parallel_regex_search.c3",
    "cpp": ROOT / "cpp/g/glushkov_bit_parallel_regex_search.cpp",
    "elisa": ROOT / "elisa/g/glushkov_bit_parallel_regex_search.elisa",
    "mojo": ROOT / "mojo/g/glushkov_bit_parallel_regex_search.mojo",
    "nim": ROOT / "nim/g/glushkov_bit_parallel_regex_search.nim",
    "odin": ROOT / "odin/g/glushkov_bit_parallel_regex_search.odin",
    "rust": ROOT / "rust/g/glushkov_bit_parallel_regex_search.rs",
    "v": ROOT / "v/g/glushkov_bit_parallel_regex_search.v",
    "zig": ROOT / "zig/g/glushkov_bit_parallel_regex_search.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    input_meta = workload.get("input", {})
    if (input_meta.get("text_length_range") != [0, 24]
            or input_meta.get("pattern_length_range") != [1, 32]
            or input_meta.get("maximum_symbol_positions") != 8
            or input_meta.get("maximum_valid_length") != 58):
        issues.append("input bounds mismatch")
    if (workload.get("output", {}).get("maximum_bytes") != 24
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("output or workspace bound mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        length = case.get("input_length", len(values))
        if not isinstance(values, list) or not isinstance(length, int):
            issues.append(f"invalid packed fixture shape: {case.get('id')}")
            continue
        if length < 0 or length > 58 or (not case.get("input_is_null", False) and length != len(values)):
            issues.append(f"packed fixture length mismatch: {case.get('id')}")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            issues.append(f"invalid output hex: {case.get('id')}")
            continue
        result = case.get("expected_result")
        if not isinstance(result, int):
            issues.append(f"invalid expected result type: {case.get('id')}")
            continue
        if result in (-1, -2) and payload:
            issues.append(f"error fixture writes output: {case.get('id')}")
        if result >= 0 and (len(payload) != result or result > 24):
            issues.append(f"success fixture result/byte count mismatch: {case.get('id')}")
        if result >= 0 and any(byte not in (0, 1) for byte in payload):
            issues.append(f"non-boolean output byte: {case.get('id')}")
    if not workload.get("cases"):
        issues.append("workload has no cases")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    return issues
