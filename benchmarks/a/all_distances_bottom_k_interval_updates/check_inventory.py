"""Static package inventory checks; ports are never compiled or executed here."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/a/all_distances_bottom_k_interval_updates"
ALGORITHM = "all_distances_bottom_k_interval_updates"
LANGUAGE_PATHS = {
    "c": "c/a/all_distances_bottom_k_interval_updates.c",
    "c3": "c3/a/all_distances_bottom_k_interval_updates.c3",
    "cpp": "cpp/a/all_distances_bottom_k_interval_updates.cpp",
    "elisa": "elisa/a/all_distances_bottom_k_interval_updates.elisa",
    "mojo": "mojo/a/all_distances_bottom_k_interval_updates.mojo",
    "nim": "nim/a/all_distances_bottom_k_interval_updates.nim",
    "odin": "odin/a/all_distances_bottom_k_interval_updates.odin",
    "rust": "rust/a/all_distances_bottom_k_interval_updates.rs",
    "v": "v/a/all_distances_bottom_k_interval_updates.v",
    "zig": "zig/a/all_distances_bottom_k_interval_updates.zig",
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
            or inventory.get("languages") != LANGUAGE_PATHS
            or inventory.get("contract", {}).get("maximum_valid_input_words") != 98
            or inventory.get("contract", {}).get("maximum_parseable_input_words") != 99
            or inventory.get("contract", {}).get("maximum_output_bytes") != 776
            or inventory.get("workspace_bytes") != 4096
            or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("inventory identity, language map, ABI, or bounds differ from contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"symbol marker missing from {relative}")
    cases = workload.get("cases", [])
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(case_ids) != len(cases) or len(case_ids) != len(set(case_ids)):
        issues.append("fixture IDs must be unique objects")
    for case in cases:
        values = case.get("input_values", [])
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            issues.append(f"input length mismatch: {case.get('id')}")
        try:
            raw = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            raw = b""
            issues.append(f"malformed expected output hex: {case.get('id')}")
        result = case.get("expected_result")
        if type(result) is not int:
            issues.append(f"missing expected result: {case.get('id')}")
        elif result >= 0 and len(raw) != result:
            issues.append(f"expected byte count mismatch: {case.get('id')}")
        elif result < 0 and raw:
            issues.append(f"error fixture has output bytes: {case.get('id')}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in ("1281100.1281133", "all_distances_sketch_bottom_k",
                   "all_distances_sketch_k_mins", "arbitrary-arrival"):
        if phrase not in readme:
            issues.append(f"README missing provenance/distinction phrase: {phrase}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    errors = check_inventory()
    if errors:
        raise SystemExit("\n".join(errors))
    print("static inventory looks consistent")
