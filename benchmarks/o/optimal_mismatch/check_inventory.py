"""Static package and fixture inventory for Optimal Mismatch."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as direct_result
from .primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": (ROOT / "c/o/optimal_mismatch.c", "c/o/optimal_mismatch.c"),
    "c3": (ROOT / "c3/o/optimal_mismatch.c3", "c3/o/optimal_mismatch.c3"),
    "cpp": (ROOT / "cpp/o/optimal_mismatch.cpp", "cpp/o/optimal_mismatch.cpp"),
    "elisa": (ROOT / "elisa/o/optimal_mismatch.elisa", "elisa/o/optimal_mismatch.elisa"),
    "mojo": (ROOT / "mojo/o/optimal_mismatch.mojo", "mojo/o/optimal_mismatch.mojo"),
    "nim": (ROOT / "nim/o/optimal_mismatch.nim", "nim/o/optimal_mismatch.nim"),
    "odin": (ROOT / "odin/o/optimal_mismatch.odin", "odin/o/optimal_mismatch.odin"),
    "rust": (ROOT / "rust/o/optimal_mismatch.rs", "rust/o/optimal_mismatch.rs"),
    "v": (ROOT / "v/o/optimal_mismatch.v", "v/o/optimal_mismatch.v"),
    "zig": (ROOT / "zig/o/optimal_mismatch.zig", "zig/o/optimal_mismatch.zig"),
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "optimal_mismatch"
            or workload.get("function_symbol") != "optimal_mismatch"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload metadata differs from the package contract")
    spec = workload.get("input", {})
    if (spec.get("text_length_range") != [0, 256]
            or spec.get("pattern_length_range") != [1, 16]
            or spec.get("byte_range") != [0, 127]
            or spec.get("maximum_valid_input_length") != 274
            or spec.get("maximum_parseable_input_length") != 274
            or workload.get("measurement", {}).get("comparison_model")
                != "i64_array_scalar_call"):
        issues.append("workload bounds or measurement metadata differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload has no fixture list")
        cases = []
    seen: set[str] = set()
    max_frame_seen = False
    null_empty_seen = False
    null_limit_seen = False
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
            issues.append(f"fixture has no input_values: {case_id}")
            continue
        input_length = case.get("input_length", len(values))
        is_null = case.get("input_is_null", False)
        if type(input_length) is not int or type(is_null) is not bool:
            issues.append(f"bad null/length metadata: {case_id}")
            continue
        if is_null:
            if values:
                issues.append(f"null fixture must carry no values: {case_id}")
            null_empty_seen |= input_length == 0
            null_limit_seen |= input_length == 274
        elif input_length != len(values):
            issues.append(f"fixture length mismatch: {case_id}")
            continue
        arguments = {"length": input_length, "input_is_null": is_null}
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary reference disagrees: {case_id}")
        if direct_result(values, **arguments) != expected:
            issues.append(f"direct reference disagrees: {case_id}")
        if not is_null and len(values) == 274:
            max_frame_seen = True
    if not max_frame_seen:
        issues.append("workload lacks a maximum-length valid frame")
    if not null_empty_seen or not null_limit_seen:
        issues.append("workload lacks null frames at lengths 0 and 274")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif "optimal_mismatch" not in path.read_text(encoding="utf-8"):
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
