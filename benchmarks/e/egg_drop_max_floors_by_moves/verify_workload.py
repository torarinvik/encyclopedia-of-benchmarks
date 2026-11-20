"""Static package and dual-reference checks for the move-count egg-drop DP."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_EGGS,
    MAX_MOVES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "egg_drop_max_floors_by_moves"
METHOD_URLS = (
    "https://doi.org/10.1080/0025570X.2004.11953281",
    "https://www.jstor.org/stable/3219201",
)
PORTS = (
    "c/e/egg_drop_max_floors_by_moves.c", "c3/e/egg_drop_max_floors_by_moves.c3",
    "cpp/e/egg_drop_max_floors_by_moves.cpp", "elisa/e/egg_drop_max_floors_by_moves.elisa",
    "mojo/e/egg_drop_max_floors_by_moves.mojo", "nim/e/egg_drop_max_floors_by_moves.nim",
    "odin/e/egg_drop_max_floors_by_moves.odin", "rust/e/egg_drop_max_floors_by_moves.rs",
    "v/e/egg_drop_max_floors_by_moves.v", "zig/e/egg_drop_max_floors_by_moves.zig",
)


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for port in PORTS:
        path = ROOT / port
        if not path.is_file() or SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported port symbol: {port}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    workspace = workload.get("workspace", {})
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_meta, dict)
            or input_meta.get("eggs_range") != [0, MAX_EGGS]
            or input_meta.get("moves_range") != [0, MAX_MOVES]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1
            or input_meta.get("null_input_result") != -1):
        issues.append("input bounds or framing differ")
    if (not isinstance(output_meta, dict)
            or output_meta.get("valid_result_range") != [0, MAX_RESULT]
            or output_meta.get("zero_egg_result") != 0
            or output_meta.get("zero_move_result") != 0
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output contract differs")
    if (not isinstance(workspace, dict)
            or workspace.get("bytes") != MAX_WORKSPACE_BYTES
            or not isinstance(source, dict)
            or source.get("method_urls") != list(METHOD_URLS)):
        issues.append("workspace or source references differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload fixture")
            continue
        if case["id"] in seen:
            issues.append(f"duplicate fixture id: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int):
            issues.append(f"invalid fixture fields: {case['id']}")
            continue
        if (primary_expected(values, is_null, length) != expected
                or independent_expected(values, is_null, length) != expected):
            issues.append(f"dual-reference mismatch: {case['id']}")
    readme = PACKAGE / "README.md"
    rights = PACKAGE / "RIGHTS.md"
    if readme.is_file() and rights.is_file():
        readme_text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        if any(url not in readme_text or url not in rights_text for url in METHOD_URLS):
            issues.append("Boardman source attribution is missing")
        for target in re.findall(r"\]\(([^)]+)\)", readme_text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
