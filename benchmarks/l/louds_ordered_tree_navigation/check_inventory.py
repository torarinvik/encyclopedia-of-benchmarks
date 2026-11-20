"""Static package, fixture, and dual-reference inventory checks."""

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
SYMBOL = "louds_ordered_tree_navigation"
SOURCE_DOI = "10.1007/978-1-4939-2864-4_641"
PORTS = {
    "c": ("c", "c"), "c3": ("c3", "c3"), "cpp": ("cpp", "cpp"),
    "elisa": ("elisa", "elisa"), "mojo": ("mojo", "mojo"),
    "nim": ("nim", "nim"), "odin": ("odin", "odin"),
    "rust": ("rust", "rs"), "v": ("v", "v"), "zig": ("zig", "zig"),
}
REQUIRED_CASES = {
    "singleton-empty", "singleton-navigation", "chain-navigation",
    "branching-navigation", "bfs-remapping", "missing-child-rank",
    "maximum-node-count", "maximum-valid-frame", "maximum-output-queries", "forward-parent-invalid",
    "invalid-opcode", "maximum-parseable-trailing-word", "null-input",
    "null-output", "short-output",
}


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        if workload is None:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("source", {}).get("doi") != SOURCE_DOI
            or inventory.get("contract", {}).get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or inventory.get("contract", {}).get("maximum_parseable_input_words") != MAX_INPUT_LENGTH
            or inventory.get("contract", {}).get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or inventory.get("contract", {}).get("workspace_bytes") != WORKSPACE_BYTES):
        issues.append("inventory identity, source, or bounds differ from the references")

    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("book_chapter_doi") != SOURCE_DOI
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
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
        expected_result = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected_result) is not int or type(input_is_null) is not bool
                or type(output_is_null) is not bool
                or capacity is not None and (type(capacity) is not int or capacity < 0)):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        options = {
            "capacity": capacity,
            "output_is_null": output_is_null,
            "input_is_null": input_is_null,
            "input_length": length,
        }
        data = None if input_is_null else values
        primary = primary_output(data, **options)
        independent = independent_output(data, **options)
        if primary != independent or primary[0] != expected_result:
            issues.append(f"fixture disagrees with references: {case_id}")
    if len(seen) != len(cases):
        issues.append("workload case IDs must be unique")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for phrase in (SOURCE_DOI, "DFUDS", "BP Representation", "rank_1", "select_0"):
        if phrase not in readme:
            issues.append(f"README omits the source/audit detail: {phrase}")
    if SOURCE_DOI not in rights or "clean-room" not in rights.lower():
        issues.append("rights and provenance note is incomplete")
    for language, (directory, extension) in PORTS.items():
        relative = f"{directory}/l/{SYMBOL}.{extension}"
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
