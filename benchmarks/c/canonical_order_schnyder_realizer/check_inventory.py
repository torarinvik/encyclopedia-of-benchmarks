"""Static inventory and fixture/reference checker; it does not run native ports."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "canonical_order_schnyder_realizer"
DOI = "10.1007/978-1-4939-2864-4_650"
PORTS = {
    "c": "c/c/canonical_order_schnyder_realizer.c",
    "c3": "c3/c/canonical_order_schnyder_realizer.c3",
    "cpp": "cpp/c/canonical_order_schnyder_realizer.cpp",
    "elisa": "elisa/c/canonical_order_schnyder_realizer.elisa",
    "mojo": "mojo/c/canonical_order_schnyder_realizer.mojo",
    "nim": "nim/c/canonical_order_schnyder_realizer.nim",
    "odin": "odin/c/canonical_order_schnyder_realizer.odin",
    "rust": "rust/c/canonical_order_schnyder_realizer.rs",
    "v": "v/c/canonical_order_schnyder_realizer.v",
    "zig": "zig/c/canonical_order_schnyder_realizer.zig",
}
REQUIRED_CASES = {
    "triangle-no-interior-roots", "four-vertex-single-parent-triple",
    "maximum-eight-vertex-bipyramid", "invalid-noncanonical-prefix-order",
    "maximum-parseable-trailing-word", "invalid-duplicate-order-vertex",
    "null-input", "null-output", "short-output",
}


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        if workload is None:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if not isinstance(inventory, dict) or not isinstance(workload, dict):
        return ["inventory and workload must be JSON objects"]

    contract = inventory.get("contract", {})
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("source", {}).get("doi") != DOI
            or contract.get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_input_words") != MAX_INPUT_LENGTH
            or contract.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or contract.get("workspace_bytes") != WORKSPACE_BYTES
            or contract.get("output_layout") != "[n,(interior_vertex,parent_T1,parent_T2,parent_T3)* in canonical order]"):
        issues.append("inventory identity, provenance, output layout, or bounds differ")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("book_chapter_doi") != DOI
            or input_contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_contract.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or output_contract.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload identity, provenance, ABI, or bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be an array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        result = case.get("expected_result")
        null_input = case.get("input_is_null", False)
        null_output = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(result) is not int or type(null_input) is not bool
                or type(null_output) is not bool
                or capacity is not None and (type(capacity) is not int or capacity < 0)):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        options = {"capacity": capacity, "output_is_null": null_output,
                   "input_is_null": null_input, "input_length": length}
        data = None if null_input else values
        primary = primary_output(data, **options)
        independent = independent_output(data, **options)
        if primary != independent or primary[0] != result:
            issues.append(f"fixture disagrees with references: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    normalized_readme = " ".join(readme.split())
    for phrase in (DOI, "Lemma 3", "T1 is rooted at `u`", "T2 at `v`", "T3 at `w`",
                   "out T1, in T2, out T3, in T1, out T2, in T3", "reverse", "56", "57"):
        if phrase not in normalized_readme:
            issues.append(f"README omits source/contract detail: {phrase}")
    if DOI not in rights or "clean-room" not in rights.lower():
        issues.append("rights and provenance note is incomplete")
    independent_source = (PACKAGE / "independent_oracle.py").read_text(encoding="utf-8")
    if "canonical_order_maximal_plane_triangulation" in independent_source:
        issues.append("independent reference must not import the primary package parser")

    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing {language} export symbol: {relative}")
        if inventory.get("languages", {}).get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} port path")
    for filename in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    return issues
