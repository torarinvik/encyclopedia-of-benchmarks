"""Static contract, fixture, and language-port inventory for Zhu–Takaoka search."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": (ROOT / "c/z/zhu_takaoka_search.c", "c/z/zhu_takaoka_search.c"),
    "c3": (ROOT / "c3/z/zhu_takaoka_search.c3", "c3/z/zhu_takaoka_search.c3"),
    "cpp": (ROOT / "cpp/z/zhu_takaoka_search.cpp", "cpp/z/zhu_takaoka_search.cpp"),
    "elisa": (ROOT / "elisa/z/zhu_takaoka_search.elisa", "elisa/z/zhu_takaoka_search.elisa"),
    "mojo": (ROOT / "mojo/z/zhu_takaoka_search.mojo", "mojo/z/zhu_takaoka_search.mojo"),
    "nim": (ROOT / "nim/z/zhu_takaoka_search.nim", "nim/z/zhu_takaoka_search.nim"),
    "odin": (ROOT / "odin/z/zhu_takaoka_search.odin", "odin/z/zhu_takaoka_search.odin"),
    "rust": (ROOT / "rust/z/zhu_takaoka_search.rs", "rust/z/zhu_takaoka_search.rs"),
    "v": (ROOT / "v/z/zhu_takaoka_search.v", "v/z/zhu_takaoka_search.v"),
    "zig": (ROOT / "zig/z/zhu_takaoka_search.zig", "zig/z/zhu_takaoka_search.zig"),
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "zhu_takaoka_search"
            or workload.get("function_symbol") != "zhu_takaoka_search"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload metadata does not match the scalar contract")
    input_spec = workload.get("input", {})
    if (input_spec.get("text_length_range") != [0, 256]
            or input_spec.get("pattern_length_range") != [2, 16]
            or input_spec.get("symbol_range") != [0, 15]
            or input_spec.get("maximum_valid_input_length") != 274
            or input_spec.get("maximum_parseable_input_length") != 274
            or workload.get("measurement", {}).get("comparison_model")
                != "i64_array_scalar_call"):
        issues.append("workload bounds or measurement metadata differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload must contain cases")
        cases = []
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"invalid or duplicate case id: {case_id}")
            continue
        seen.add(case_id)
        if not isinstance(values, list):
            issues.append(f"fixture has no input array: {case_id}")
            continue
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values))
        if type(input_is_null) is not bool or type(input_length) is not int:
            issues.append(f"invalid fixture null/length metadata: {case_id}")
            continue
        if (input_is_null and values) or (not input_is_null and input_length != len(values)):
            issues.append(f"fixture framing mismatch: {case_id}")
            continue
        arguments = {"length": input_length, "input_is_null": input_is_null}
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary reference disagrees with fixture: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent reference disagrees with fixture: {case_id}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if "zhu_takaoka_search" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language} port")
        if f"](../../../{relative})" not in readme:
            issues.append(f"missing README link for {language}")
    for document in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / document).is_file():
            issues.append(f"missing package document: {document}")
    return issues
