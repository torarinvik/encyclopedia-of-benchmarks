"""Static package, workload, port, and dual-reference review helpers."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_BASE,
    MAX_DIGITS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "polydivisible_prefix_search"
PORTS = (
    "c/p/polydivisible_prefix_search.c",
    "c3/p/polydivisible_prefix_search.c3",
    "cpp/p/polydivisible_prefix_search.cpp",
    "elisa/p/polydivisible_prefix_search.elisa",
    "mojo/p/polydivisible_prefix_search.mojo",
    "nim/p/polydivisible_prefix_search.nim",
    "odin/p/polydivisible_prefix_search.odin",
    "rust/p/polydivisible_prefix_search.rs",
    "v/p/polydivisible_prefix_search.v",
    "zig/p/polydivisible_prefix_search.zig",
)


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                "primary_oracle.py", "independent_oracle.py", "verify_workload.py")
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file() or SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported port: {relative}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    source = workload.get("source")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_meta, dict)
            or input_meta.get("base_range") != [2, MAX_BASE]
            or input_meta.get("maximum_digit_length_range") != [1, MAX_DIGITS]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bound or framing differs")
    if (not isinstance(output_meta, dict)
            or output_meta.get("result_range") != [0, 999999]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output contract differs")
    if (not isinstance(source, dict)
            or source.get("definition_url") != "https://oeis.org/A397953"
            or not str(source.get("incremental_generation_url", "")).startswith("https://web.stanford.edu/")):
        issues.append("source metadata differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be nonempty"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if (primary_expected(values, is_null, length) != expected
                or independent_expected(values, is_null, length) != expected):
            issues.append(f"dual-reference mismatch: {case_id}")
    readme = PACKAGE / "README.md"
    rights = PACKAGE / "RIGHTS.md"
    if readme.is_file() and rights.is_file():
        text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        for url in ("https://oeis.org/A397953",
                    "https://web.stanford.edu/class/archive/cs/cs106ax/cs106ax.1252/res/handouts/16-CS106AX-Midterm"):
            if url not in text or url not in rights_text:
                issues.append(f"missing provenance link: {url}")
        for target in re.findall(r"\]\(([^)]+)\)", text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
