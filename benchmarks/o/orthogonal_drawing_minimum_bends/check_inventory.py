"""Static package, workload, and reference checker; never calls native ports."""

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
SYMBOL = "orthogonal_drawing_minimum_bends"
DOI = "10.1007/978-1-4939-2864-4_651"
PORTS = {
    "c": "c/o/orthogonal_drawing_minimum_bends.c",
    "c3": "c3/o/orthogonal_drawing_minimum_bends.c3",
    "cpp": "cpp/o/orthogonal_drawing_minimum_bends.cpp",
    "elisa": "elisa/o/orthogonal_drawing_minimum_bends.elisa",
    "mojo": "mojo/o/orthogonal_drawing_minimum_bends.mojo",
    "nim": "nim/o/orthogonal_drawing_minimum_bends.nim",
    "odin": "odin/o/orthogonal_drawing_minimum_bends.odin",
    "rust": "rust/o/orthogonal_drawing_minimum_bends.rs",
    "v": "v/o/orthogonal_drawing_minimum_bends.v",
    "zig": "zig/o/orthogonal_drawing_minimum_bends.zig",
}
REQUIRED_CASES = {
    "triangle-one-bend", "square-cycle-zero-bends",
    "tetrahedral-embedding-three-bends",
    "maximum-eight-vertex-four-regular-map",
    "maximum-parseable-trailing-word", "pinched-disconnected-vertex-link",
    "invalid-face-orientation",
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
            or contract.get("workspace_bytes") != WORKSPACE_BYTES):
        issues.append("inventory identity, provenance, or bounds differ")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("book_chapter_doi") != DOI
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or not isinstance(input_spec.get("plane_graph"), str)
            or "vertex link is one connected cycle" not in input_spec.get("plane_graph", "")
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload identity, ABI, provenance, or bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be an array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        result = case.get("expected_result")
        capacity = case.get("output_capacity")
        null_input = case.get("input_is_null", False)
        null_output = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(result) is not int or type(null_input) is not bool
                or type(null_output) is not bool
                or (capacity is not None and (type(capacity) is not int or capacity < 0))):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        data = None if null_input else values
        options = {"capacity": capacity, "output_is_null": null_output,
                   "input_is_null": null_input, "input_length": length}
        primary = primary_output(data, **options)
        independent = independent_output(data, **options)
        expected_hex = case.get("expected_output_hex")
        if (primary != independent or primary[0] != result
                or not isinstance(expected_hex, str) or primary[1].hex() != expected_hex.lower()):
            issues.append(f"fixture disagrees with references: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    normalized_readme = " ".join(readme.split())
    for phrase in (DOI, "2*deg(f)-4", "2*deg(f)+4", "lower bound one",
                   "unit cost", "minimum bend count", "connected cycle", "78", "79"):
        if phrase not in normalized_readme:
            issues.append(f"README omits source/contract detail: {phrase}")
    if DOI not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")
    if "min_cost_max_flow" in (PACKAGE / "independent_oracle.py").read_text(encoding="utf-8"):
        issues.append("independent reference must be package-independent")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing {language} export symbol: {relative}")
        if inventory.get("languages", {}).get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} path")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
