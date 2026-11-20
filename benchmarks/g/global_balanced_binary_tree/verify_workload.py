"""Static package, workload, source, and dual-reference review helpers."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "global_balanced_binary_tree"
PORTS = (
    "c/g/global_balanced_binary_tree.c",
    "c3/g/global_balanced_binary_tree.c3",
    "cpp/g/global_balanced_binary_tree.cpp",
    "elisa/g/global_balanced_binary_tree.elisa",
    "mojo/g/global_balanced_binary_tree.mojo",
    "nim/g/global_balanced_binary_tree.nim",
    "odin/g/global_balanced_binary_tree.odin",
    "rust/g/global_balanced_binary_tree.rs",
    "v/g/global_balanced_binary_tree.v",
    "zig/g/global_balanced_binary_tree.zig",
)
SOURCES = (
    "https://www.timothywang.ca/OI-wiki/ds/global-bst/",
    "https://oiwiki.wiki/ds/global-bst/",
)


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or SYMBOL not in source.read_text(encoding="utf-8"):
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
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_meta, dict)
            or input_meta.get("vertex_count_range") != [1, MAX_N]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bound or framing differs")
    if (not isinstance(output_meta, dict)
            or output_meta.get("result_range") != [0, MAX_RESULT]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("checksum result bounds differ")
    source = workload.get("source")
    if not isinstance(source, dict) or any(
            source.get(key) != url for key, url in zip(
                ("english_description_url", "chinese_description_url"), SOURCES)):
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
        readme_text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        for url in SOURCES:
            if url not in readme_text or url not in rights_text:
                issues.append(f"missing provenance link: {url}")
        for target in re.findall(r"\]\(([^)]+)\)", readme_text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
