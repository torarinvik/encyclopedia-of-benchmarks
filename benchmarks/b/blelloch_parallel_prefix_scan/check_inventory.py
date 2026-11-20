"""Static source and workload inventory checker; not run while drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/blelloch_parallel_prefix_scan"
ALGORITHM = "blelloch_parallel_prefix_scan"
LANGUAGE_PATHS = {
    "c": "c/b/blelloch_parallel_prefix_scan.c",
    "c3": "c3/b/blelloch_parallel_prefix_scan.c3",
    "cpp": "cpp/b/blelloch_parallel_prefix_scan.cpp",
    "elisa": "elisa/b/blelloch_parallel_prefix_scan.elisa",
    "mojo": "mojo/b/blelloch_parallel_prefix_scan.mojo",
    "nim": "nim/b/blelloch_parallel_prefix_scan.nim",
    "odin": "odin/b/blelloch_parallel_prefix_scan.odin",
    "rust": "rust/b/blelloch_parallel_prefix_scan.rs",
    "v": "v/b/blelloch_parallel_prefix_scan.v",
    "zig": "zig/b/blelloch_parallel_prefix_scan.zig",
}
CASE_IDS = {
    "single_element", "power_of_two_eight", "non_power_of_two_negative_values",
    "all_zero_non_power_of_two", "alternating_bound_values", "invalid_zero_items",
    "invalid_item_count", "value_out_of_range", "trailing_input",
    "short_output_capacity", "null_output", "null_input",
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
        issues.append("inventory identity, ABI, or language map differs from contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"export marker missing in {relative}")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed set")
    if set(inventory.get("fixture_ids", [])) != set(ids):
        issues.append("inventory fixture IDs differ from workload")
    if (workload.get("input", {}).get("maximum_valid_length") != 65
            or workload.get("input", {}).get("maximum_parseable_length") != 66
            or workload.get("output", {}).get("maximum_output_bytes") != 512
            or workload.get("workspace", {}).get("bytes") != 2048
            or inventory.get("contract", {}).get("maximum_valid_input_length") != 65
            or inventory.get("contract", {}).get("maximum_parseable_input_length") != 66
            or inventory.get("contract", {}).get("maximum_output_bytes") != 512
            or inventory.get("contract", {}).get("workspace_bytes") != 2048):
        issues.append("input, output, or workspace bounds differ from contract")
    return issues
