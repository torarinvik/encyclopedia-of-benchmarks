"""Static package and fixture inventory; this module never calls native ports."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_result as independent_result
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "c_connected_clustered_embedding_condition"
CHAPTER_DOI = "10.1007/978-1-4939-2864-4_655"
THEOREM_DOI = "10.1007/3-540-60313-1_145"
PORTS = {
    "c":"c/c/c_connected_clustered_embedding_condition.c",
    "c3":"c3/c/c_connected_clustered_embedding_condition.c3",
    "cpp":"cpp/c/c_connected_clustered_embedding_condition.cpp",
    "elisa":"elisa/c/c_connected_clustered_embedding_condition.elisa",
    "mojo":"mojo/c/c_connected_clustered_embedding_condition.mojo",
    "nim":"nim/c/c_connected_clustered_embedding_condition.nim",
    "odin":"odin/c/c_connected_clustered_embedding_condition.odin",
    "rust":"rust/c/c_connected_clustered_embedding_condition.rs",
    "v":"v/c/c_connected_clustered_embedding_condition.v",
    "zig":"zig/c/c_connected_clustered_embedding_condition.zig",
}
REQUIRED_CASES = {
    "triangle-single-edge-cluster-valid",
    "k4-outer-triangle-encloses-outsider",
    "k4-interior-face-cluster-valid",
    "no-clusters-planar-embedding",
    "invalid-disconnected-induced-cluster",
    "invalid-crossing-laminar-masks",
    "invalid-duplicate-mask",
    "invalid-nonplanar-k5-rotation",
    "invalid-outer-dart-not-an-edge",
    "maximum-54-word-stacked-triangulation",
    "maximum-parseable-length-trailing-word",
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

    expected_measurement = {
        "comparison_model":"i64_array_scalar_call",
        "sample_count":7,
        "warmup_rounds":2,
        "repetitions_per_sample":1000,
    }
    contract = inventory.get("contract", {})
    source = inventory.get("source", {})
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or source.get("chapter_doi") != CHAPTER_DOI
            or source.get("theorem_source", "").find(THEOREM_DOI) < 0
            or contract.get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_input_words") != MAX_PARSEABLE_INPUT_LENGTH
            or contract.get("workspace_bytes") != 8192
            or contract.get("measurement") != expected_measurement):
        issues.append("inventory identity, provenance, or bounds differ")
    input_spec = workload.get("input", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("book_chapter_doi") != CHAPTER_DOI
            or THEOREM_DOI not in workload.get("source", {}).get("original_theorem_source", "")
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("measurement") != expected_measurement
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("workload identity, provenance, or bounds differ")

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
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values)
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        data = None if input_is_null else values
        primary = primary_result(data, input_is_null=input_is_null, input_length=length)
        independent = independent_result(data, input_is_null=input_is_null, input_length=length)
        if primary != independent or primary != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    normalized = " ".join(readme.split()).lower()
    for phrase in (CHAPTER_DOI, THEOREM_DOI, "theorem 3", "fixed-embedding", "pq-tree",
                   "rotation_system_planarity_test", "c-connected"):
        if phrase.lower() not in normalized:
            issues.append(f"README omits source or contract detail: {phrase}")
    if CHAPTER_DOI not in rights or THEOREM_DOI not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} symbol: {relative}")
        if inventory.get("languages", {}).get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} source path")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
