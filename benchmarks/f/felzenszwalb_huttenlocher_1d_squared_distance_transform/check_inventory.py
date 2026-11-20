"""Static package inventory checker; not run while drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/felzenszwalb_huttenlocher_1d_squared_distance_transform"
ALGORITHM = "felzenszwalb_huttenlocher_1d_squared_distance_transform"
LANGUAGE_PATHS = {
    "c": "c/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.c",
    "c3": "c3/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.c3",
    "cpp": "cpp/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.cpp",
    "elisa": "elisa/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.elisa",
    "mojo": "mojo/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.mojo",
    "nim": "nim/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.nim",
    "odin": "odin/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.odin",
    "rust": "rust/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.rs",
    "v": "v/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.v",
    "zig": "zig/f/felzenszwalb_huttenlocher_1d_squared_distance_transform.zig",
}
CASE_IDS = {
    "single_site", "equal_value_integer_crossing", "dominated_middle_site",
    "asymmetric_costs", "maximum_costs", "invalid_zero_sites",
    "invalid_too_many_sites", "negative_cost", "trailing_input",
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
    if (workload.get("input", {}).get("maximum_valid_length") != 129
            or workload.get("input", {}).get("maximum_parseable_length") != 130
            or workload.get("output", {}).get("maximum_output_bytes") != 2048
            or workload.get("workspace", {}).get("bytes") != 4096
            or inventory.get("contract", {}).get("maximum_valid_input_length") != 129
            or inventory.get("contract", {}).get("maximum_parseable_input_length") != 130
            or inventory.get("contract", {}).get("maximum_output_bytes") != 2048
            or inventory.get("contract", {}).get("workspace_bytes") != 4096):
        issues.append("input, output, or workspace bounds differ from contract")
    return issues
