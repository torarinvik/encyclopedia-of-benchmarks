"""Static package, bounded workload, and dual-reference checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "alphabetic_anagrams"
METHOD_URLS = (
    "https://cs.stanford.edu/~knuth/taocp.html",
    "https://dlmf.nist.gov/26.16",
)
PORTS = (
    "c/a/alphabetic_anagrams.c", "c3/a/alphabetic_anagrams.c3",
    "cpp/a/alphabetic_anagrams.cpp", "elisa/a/alphabetic_anagrams.elisa",
    "mojo/a/alphabetic_anagrams.mojo", "nim/a/alphabetic_anagrams.nim",
    "odin/a/alphabetic_anagrams.odin", "rust/a/alphabetic_anagrams.rs",
    "v/a/alphabetic_anagrams.v", "zig/a/alphabetic_anagrams.zig",
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
            or input_meta.get("n_range") != [0, 8]
            or input_meta.get("symbol_range") != [0, 25]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1
            or input_meta.get("null_input_result") != -1):
        issues.append("input bounds or framing differ")
    if (not isinstance(output_meta, dict)
            or output_meta.get("valid_result_range") != [1, 40320]
            or output_meta.get("empty_word_result") != 1
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output contract differs")
    if (not isinstance(workspace, dict)
            or workspace.get("bytes") != MAX_WORKSPACE_BYTES
            or not isinstance(source, dict)
            or source.get("method_urls") != list(METHOD_URLS)):
        issues.append("workspace or generic-method provenance differs")
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
            issues.append("generic combinatorics attribution is missing")
        for target in re.findall(r"\]\(([^)]+)\)", readme_text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
