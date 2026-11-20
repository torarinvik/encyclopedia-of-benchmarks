"""Static inventory, workload, and reference preflight; never calls native ports."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_result as independent_result
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "thomassen_convex_drawing_extendibility"
DOI = "10.1007/978-1-4939-2864-4_652"
PORTS = {
    "c": "c/t/thomassen_convex_drawing_extendibility.c",
    "c3": "c3/t/thomassen_convex_drawing_extendibility.c3",
    "cpp": "cpp/t/thomassen_convex_drawing_extendibility.cpp",
    "elisa": "elisa/t/thomassen_convex_drawing_extendibility.elisa",
    "mojo": "mojo/t/thomassen_convex_drawing_extendibility.mojo",
    "nim": "nim/t/thomassen_convex_drawing_extendibility.nim",
    "odin": "odin/t/thomassen_convex_drawing_extendibility.odin",
    "rust": "rust/t/thomassen_convex_drawing_extendibility.rs",
    "v": "v/t/thomassen_convex_drawing_extendibility.v",
    "zig": "zig/t/thomassen_convex_drawing_extendibility.zig",
}
REQUIRED_CASES = {
    "outer-triangle-no-interior",
    "tetrahedron-extendible",
    "three-outer-path-condition-fails",
    "inner-component-attached-to-one-side",
    "nonouter-edge-contained-in-one-side",
    "inner-cycle-has-fewer-than-three-high-degree-vertices",
    "maximum-eight-vertex-triangulation",
    "pinched-embedding-disconnected-vertex-link",
    "maximum-parseable-trailing-word",
    "invalid-repeated-face-orientation",
    "null-input",
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
    source = inventory.get("source", {})
    measurement = workload.get("measurement", {})
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or source.get("doi") != DOI
            or contract.get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_input_words") != MAX_INPUT_LENGTH
            or contract.get("workspace_bytes") != WORKSPACE_BYTES
            or contract.get("measurement") != {
                "comparison_model": "i64_array_scalar_call",
                "sample_count": 7,
                "warmup_rounds": 2,
                "repetitions_per_sample": 1000,
            }):
        issues.append("inventory identity, provenance, or bounds differ")

    input_spec = workload.get("input", {})
    source_spec = workload.get("source", {})
    plane_embedding = input_spec.get("plane_embedding")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source_spec.get("book_chapter_doi") != DOI
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or not isinstance(plane_embedding, str)
            or "one connected cycle" not in plane_embedding
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or measurement != contract.get("measurement")):
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
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        null_input = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected) is not int or type(null_input) is not bool):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        data = None if null_input else values
        options = {"input_is_null": null_input, "input_length": length}
        primary = primary_result(data, **options)
        independent = independent_result(data, **options)
        if primary != independent or primary != expected:
            issues.append(f"fixture disagrees with references: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    normalized_readme = " ".join(readme.split())
    for phrase in (DOI, "Theorem 1", "92", "93", "three internally vertex-disjoint paths",
                   "single side path", "at least three", "connected cycle"):
        if phrase not in normalized_readme:
            issues.append(f"README omits source or contract detail: {phrase}")
    if DOI not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} export symbol: {relative}")
        if inventory.get("languages", {}).get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} source path")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
