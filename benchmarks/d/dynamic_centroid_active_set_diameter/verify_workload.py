"""Static package and dual-reference review helpers; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_N,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "dynamic_centroid_active_set_diameter"
SOURCE = "https://www.timothywang.ca/OI-wiki/graph/dynamic-tree-divide/"
PORTS = (
    "c/d/dynamic_centroid_active_set_diameter.c",
    "c3/d/dynamic_centroid_active_set_diameter.c3",
    "cpp/d/dynamic_centroid_active_set_diameter.cpp",
    "elisa/d/dynamic_centroid_active_set_diameter.elisa",
    "mojo/d/dynamic_centroid_active_set_diameter.mojo",
    "nim/d/dynamic_centroid_active_set_diameter.nim",
    "odin/d/dynamic_centroid_active_set_diameter.odin",
    "rust/d/dynamic_centroid_active_set_diameter.rs",
    "v/d/dynamic_centroid_active_set_diameter.v",
    "zig/d/dynamic_centroid_active_set_diameter.zig",
)


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for relative in required:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    for relative in PORTS:
        source_path = ROOT / relative
        if not source_path.is_file() or SYMBOL not in source_path.read_text(encoding="utf-8"):
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
            or input_meta.get("operation_count_range") != [0, MAX_OPERATIONS]
            or input_meta.get("exact_length") != "n + 1 + q"
            or input_meta.get("operation_encoding")
            != "-1 queries the active-set diameter; 0..n-1 toggles that vertex"
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds or frame contract differ")
    if (not isinstance(output_meta, dict)
            or output_meta.get("result_range") != [0, MAX_RESULT]
            or output_meta.get("checksum")
            != "sum(j * (diameter_after_query_j + 1)) for one-based query number j"
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output checksum bounds differ")
    source_meta = workload.get("source")
    if not isinstance(source_meta, dict) or source_meta.get("description_url") != SOURCE:
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
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(input_length) is not int
                or type(input_is_null) is not bool or type(expected) is not int
                or input_length != (1 if input_is_null else len(values))
                or (not input_is_null and len(values) > MAX_PARSEABLE_INPUT_LENGTH)):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if (primary_expected(values, input_is_null, input_length) != expected
                or independent_expected(values, input_is_null, input_length) != expected):
            issues.append(f"dual-reference mismatch: {case_id}")

    readme = PACKAGE / "README.md"
    rights = PACKAGE / "RIGHTS.md"
    if readme.is_file() and rights.is_file():
        readme_text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        if SOURCE not in readme_text or SOURCE not in rights_text:
            issues.append("missing OI Wiki provenance link")
        for target in re.findall(r"\]\(([^)]+)\)", readme_text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
