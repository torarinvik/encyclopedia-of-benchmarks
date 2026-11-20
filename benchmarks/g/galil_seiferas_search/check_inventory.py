"""Static package and fixture inventory for Galil–Seiferas matching."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as direct_result
from .primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": (ROOT / "c/g/galil_seiferas_search.c", "c/g/galil_seiferas_search.c"),
    "c3": (ROOT / "c3/g/galil_seiferas_search.c3", "c3/g/galil_seiferas_search.c3"),
    "cpp": (ROOT / "cpp/g/galil_seiferas_search.cpp", "cpp/g/galil_seiferas_search.cpp"),
    "elisa": (ROOT / "elisa/g/galil_seiferas_search.elisa", "elisa/g/galil_seiferas_search.elisa"),
    "mojo": (ROOT / "mojo/g/galil_seiferas_search.mojo", "mojo/g/galil_seiferas_search.mojo"),
    "nim": (ROOT / "nim/g/galil_seiferas_search.nim", "nim/g/galil_seiferas_search.nim"),
    "odin": (ROOT / "odin/g/galil_seiferas_search.odin", "odin/g/galil_seiferas_search.odin"),
    "rust": (ROOT / "rust/g/galil_seiferas_search.rs", "rust/g/galil_seiferas_search.rs"),
    "v": (ROOT / "v/g/galil_seiferas_search.v", "v/g/galil_seiferas_search.v"),
    "zig": (ROOT / "zig/g/galil_seiferas_search.zig", "zig/g/galil_seiferas_search.zig"),
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "galil_seiferas_search"
            or workload.get("function_symbol") != "galil_seiferas_search"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload metadata differs from the package contract")
    spec = workload.get("input", {})
    if (spec.get("text_length_range") != [0, 128]
            or spec.get("pattern_length_range") != [1, 32]
            or spec.get("symbol_range") != [0, 15]
            or spec.get("maximum_valid_input_length") != 162
            or spec.get("maximum_parseable_input_length") != 162
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload bounds or measurement metadata differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload has no fixture list")
        cases = []
    seen: set[str] = set()
    max_frame = null_empty = null_limit = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id, values = case.get("id"), case.get("input_values")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"invalid or duplicate case id: {case_id}")
            continue
        seen.add(case_id)
        if not isinstance(values, list):
            issues.append(f"fixture has no input_values: {case_id}")
            continue
        length = case.get("input_length", len(values))
        is_null = case.get("input_is_null", False)
        if type(length) is not int or type(is_null) is not bool:
            issues.append(f"bad null/length metadata: {case_id}")
            continue
        if is_null:
            if values:
                issues.append(f"null fixture must carry no values: {case_id}")
            null_empty |= length == 0
            null_limit |= length == 162
        elif length != len(values):
            issues.append(f"fixture length mismatch: {case_id}")
            continue
        args = {"length": length, "input_is_null": is_null}
        expected = case.get("expected_result")
        if primary_result(values, **args) != expected:
            issues.append(f"primary reference disagrees: {case_id}")
        if direct_result(values, **args) != expected:
            issues.append(f"direct reference disagrees: {case_id}")
        max_frame |= not is_null and len(values) == 162
    if not max_frame:
        issues.append("workload lacks a maximum-length valid frame")
    if not null_empty or not null_limit:
        issues.append("workload lacks null frames at lengths 0 and 162")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif "galil_seiferas_search" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing symbol text in {language} port")
        if f"](../../../{relative})" not in readme:
            issues.append(f"missing README link for {language}")
    for document in ("README.md", "RIGHTS.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / document).is_file():
            issues.append(f"missing package document: {document}")
    for target in ("primary_oracle.py", "independent_oracle.py",
                   "workload.json", "RIGHTS.md", "check_inventory.py"):
        if f"]({target})" not in readme:
            issues.append(f"missing README link for {target}")
    return issues
