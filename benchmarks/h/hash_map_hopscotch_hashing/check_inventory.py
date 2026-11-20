"""Static package inventory checker; deliberately not run during source-only work."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/h/hash_map_hopscotch_hashing"
ALGORITHM = "hash_map_hopscotch_hashing"
LANGUAGE_PATHS = {
    "c": "c/h/hash_map_hopscotch_hashing.c",
    "c3": "c3/h/hash_map_hopscotch_hashing.c3",
    "cpp": "cpp/h/hash_map_hopscotch_hashing.cpp",
    "elisa": "elisa/h/hash_map_hopscotch_hashing.elisa",
    "mojo": "mojo/h/hash_map_hopscotch_hashing.mojo",
    "nim": "nim/h/hash_map_hopscotch_hashing.nim",
    "odin": "odin/h/hash_map_hopscotch_hashing.odin",
    "rust": "rust/h/hash_map_hopscotch_hashing.rs",
    "v": "v/h/hash_map_hopscotch_hashing.v",
    "zig": "zig/h/hash_map_hopscotch_hashing.zig",
}
CASE_IDS = {
    "empty-table",
    "direct-insert-hit-and-miss",
    "backward-hole-relocation",
    "circular-wraparound-relocation",
    "duplicate-insert",
    "home-bucket-neighborhood-limit",
    "max-output-success",
    "full-table-insertion-failure",
    "max-output-one-byte-short",
    "empty-output-one-byte-short",
    "null-output",
    "invalid-frame-precedes-null-output",
    "reject-inconsistent-home",
    "reject-trailing-word",
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
        issues.append("inventory identity, ABI, or language map differs from the reviewed contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"symbol marker missing in {relative}")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        values = case.get("input_values", [])
        if not case.get("input_is_null") and case.get("input_length") != len(values):
            issues.append(f"input length differs from values in {case.get('id')}")
        if case.get("expected_result", 0) >= 0:
            try:
                decoded = bytes.fromhex(case.get("expected_output_hex", ""))
            except ValueError:
                issues.append(f"invalid output hex in {case.get('id')}")
                continue
            if len(decoded) != case["expected_result"]:
                issues.append(f"output length differs from result in {case.get('id')}")

    if (workload.get("input", {}).get("maximum_valid_length") != 97
            or workload.get("input", {}).get("maximum_parseable_length") != 97
            or workload.get("output", {}).get("maximum_bytes") != 64
            or workload.get("workspace", {}).get("bytes") != 1024
            or inventory.get("contract", {}).get("maximum_input_words") != 97
            or inventory.get("contract", {}).get("maximum_output_bytes") != 64
            or inventory.get("contract", {}).get("workspace_bytes") != 1024):
        issues.append("bounded input/output/workspace values differ from the reviewed contract")
    return issues
