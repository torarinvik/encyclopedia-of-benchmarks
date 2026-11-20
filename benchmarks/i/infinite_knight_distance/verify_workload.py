"""Static package and fixture checks for infinite knight distance."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import MAX_BFS_OFFSET, expected_result as bfs_expected
from .primary_oracle import (
    MAX_COORDINATE,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "infinite_knight_distance"
METHOD_URL = "https://doi.org/10.1016/0167-8655(88)90105-5"
PORTS = (
    "c/i/infinite_knight_distance.c", "c3/i/infinite_knight_distance.c3",
    "cpp/i/infinite_knight_distance.cpp", "elisa/i/infinite_knight_distance.elisa",
    "mojo/i/infinite_knight_distance.mojo", "nim/i/infinite_knight_distance.nim",
    "odin/i/infinite_knight_distance.odin", "rust/i/infinite_knight_distance.rs",
    "v/i/infinite_knight_distance.v", "zig/i/infinite_knight_distance.zig",
)
LARGE_FIXTURES = {
    (MAX_COORDINATE, MAX_COORDINATE): MAX_RESULT,
    (-MAX_COORDINATE, 0): 500_000_000,
}


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
            or input_meta.get("coordinate_range") != [-MAX_COORDINATE, MAX_COORDINATE]
            or input_meta.get("required_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1
            or input_meta.get("null_input_result") != -1):
        issues.append("input bounds or framing differ")
    if (not isinstance(output_meta, dict)
            or output_meta.get("valid_result_range") != [0, MAX_RESULT]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output contract differs")
    if (not isinstance(workspace, dict)
            or workspace.get("bytes") != MAX_WORKSPACE_BYTES
            or not isinstance(source, dict)
            or source.get("method_url") != METHOD_URL):
        issues.append("workspace or method provenance differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    seen_large: dict[tuple[int, int], int] = {}
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
        primary = primary_expected(values, is_null, length)
        if primary != expected:
            issues.append(f"primary-reference mismatch: {case['id']}")
            continue
        if not is_null and len(values) == 2 and all(type(value) is int for value in values):
            bfs = bfs_expected(values, False, length)
            if bfs is None:
                seen_large[(values[0], values[1])] = expected
            elif bfs != expected:
                issues.append(f"bounded BFS mismatch: {case['id']}")
    if seen_large != LARGE_FIXTURES:
        issues.append("large displacement fixtures must match the documented formula values")
    readme = PACKAGE / "README.md"
    rights = PACKAGE / "RIGHTS.md"
    if readme.is_file() and rights.is_file():
        readme_text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        if METHOD_URL not in readme_text or METHOD_URL not in rights_text:
            issues.append("paper attribution is missing")
        for target in re.findall(r"\]\(([^)]+)\)", readme_text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    if MAX_BFS_OFFSET != 8:
        issues.append("bounded independent oracle domain changed unexpectedly")
    return issues


static_issues = verify_workload
