"""Static source and fixture inventory for the AVL order-statistics package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/o/ordered_set_avl_order_statistics.c",
    "c3": ROOT / "c3/o/ordered_set_avl_order_statistics.c3",
    "cpp": ROOT / "cpp/o/ordered_set_avl_order_statistics.cpp",
    "elisa": ROOT / "elisa/o/ordered_set_avl_order_statistics.elisa",
    "mojo": ROOT / "mojo/o/ordered_set_avl_order_statistics.mojo",
    "nim": ROOT / "nim/o/ordered_set_avl_order_statistics.nim",
    "odin": ROOT / "odin/o/ordered_set_avl_order_statistics.odin",
    "rust": ROOT / "rust/o/ordered_set_avl_order_statistics.rs",
    "v": ROOT / "v/o/ordered_set_avl_order_statistics.v",
    "zig": ROOT / "zig/o/ordered_set_avl_order_statistics.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "!input",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
EXPECTED_CASES = {
    "empty_set_no_operations",
    "all_order_statistic_queries",
    "idempotent_updates_and_empty_queries",
    "empty_set_query_results",
    "maximum_frame",
    "duplicate_initial_key_invalid",
    "unsorted_initial_keys_invalid",
    "zero_rank_invalid",
    "unknown_operation_invalid",
    "trailing_word_invalid",
    "null_input_invalid",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    required = ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py")
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "ordered_set_avl_order_statistics" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported symbol")
        if NULL_GUARDS[language] not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks its null-input guard")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source):
            issues.append("Elisa must use safe internal views and arrays")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            cases = workload.get("cases")
            case_ids = (
                {case.get("id") for case in cases}
                if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                else set()
            )
            if (
                workload.get("algorithm") != "ordered_set_avl_order_statistics"
                or workload.get("function_symbol") != "ordered_set_avl_order_statistics"
                or workload.get("abi") != "i64_array_scalar"
                or workload.get("input", {}).get("maximum_valid_input_length") != 98
                or workload.get("input", {}).get("maximum_parseable_input_length") != 99
                or workload.get("workspace", {}).get("bytes") != 8192
            ):
                issues.append("workload metadata differs from the package contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload cases differ from the reviewed fixture inventory")
    return issues
