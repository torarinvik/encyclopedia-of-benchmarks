"""Static package inventory checker; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/buddy_system_allocator"
ALGORITHM = "buddy_system_allocator"
LANGUAGE_PATHS = {
    "c": "c/b/buddy_system_allocator.c",
    "c3": "c3/b/buddy_system_allocator.c3",
    "cpp": "cpp/b/buddy_system_allocator.cpp",
    "elisa": "elisa/b/buddy_system_allocator.elisa",
    "mojo": "mojo/b/buddy_system_allocator.mojo",
    "nim": "nim/b/buddy_system_allocator.nim",
    "odin": "odin/b/buddy_system_allocator.odin",
    "rust": "rust/b/buddy_system_allocator.rs",
    "v": "v/b/buddy_system_allocator.v",
    "zig": "zig/b/buddy_system_allocator.zig",
}
CASE_IDS = {
    "empty-trace-initial-arena",
    "round-up-and-recursive-split",
    "free-coalesces-to-arena",
    "exhausted-arena-allocation-fails",
    "invalid-free-precedes-capacity",
    "trailing-word",
    "null-output",
    "one-byte-short-output",
    "null-input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("languages") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or language map differs from the contract")
    if "verify_workload.py" not in inventory.get("metadata", []):
        issues.append("workload verifier is missing from the inventory metadata list")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol marker missing in {relative}")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    if set(inventory.get("fixture_ids", [])) != set(ids):
        issues.append("inventory fixture IDs differ from the workload")
    for case in cases:
        values = case.get("input_values", [])
        if not case.get("input_is_null") and case.get("input_length") != len(values):
            issues.append(f"input length differs from values in {case.get('id')}")
        if case.get("expected_result", 0) >= 0:
            try:
                payload = bytes.fromhex(case.get("expected_output_hex", ""))
            except ValueError:
                issues.append(f"invalid output hex in {case.get('id')}")
                continue
            if len(payload) != case["expected_result"]:
                issues.append(f"output length differs from result in {case.get('id')}")

    if (workload.get("input", {}).get("maximum_valid_length") != 193
            or workload.get("input", {}).get("maximum_parseable_length") != 194
            or workload.get("output", {}).get("maximum_bytes") != 5640
            or workload.get("workspace", {}).get("bytes") != 16384
            or inventory.get("contract", {}).get("maximum_input_words") != 194
            or inventory.get("contract", {}).get("maximum_output_bytes") != 5640
            or inventory.get("contract", {}).get("workspace_bytes") != 16384):
        issues.append("bounded input/output/workspace values differ from the reviewed contract")
    return issues
