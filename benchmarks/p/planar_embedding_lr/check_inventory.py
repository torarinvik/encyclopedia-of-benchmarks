"""Static package inventory review; this file is not a test runner."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent

EXPECTED_LANGUAGES = [
    ("C", "c/p/planar_embedding_lr.c"),
    ("C3", "c3/p/planar_embedding_lr.c3"),
    ("C++", "cpp/p/planar_embedding_lr.cpp"),
    ("Elisa", "elisa/p/planar_embedding_lr.elisa"),
    ("Mojo", "mojo/p/planar_embedding_lr.mojo"),
    ("Nim", "nim/p/planar_embedding_lr.nim"),
    ("Odin", "odin/p/planar_embedding_lr.odin"),
    ("Rust", "rust/p/planar_embedding_lr.rs"),
    ("V", "v/p/planar_embedding_lr.v"),
    ("Zig", "zig/p/planar_embedding_lr.zig"),
]


def inventory_errors() -> list[str]:
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    errors: list[str] = []
    if inventory.get("algorithm") != "planar_embedding_lr" or inventory.get("abi") != "i64_array_bytes_output":
        errors.append("algorithm or ABI does not match the package contract")
    actual_languages = [(item["name"], item["path"]) for item in inventory["languages"]]
    if actual_languages != EXPECTED_LANGUAGES:
        errors.append("language paths do not match the pinned ten-port inventory")
    for item in inventory["languages"]:
        if item.get("symbol") != "planar_embedding_lr":
            errors.append(f"unexpected exported symbol in inventory: {item.get('path')}")
        path = ROOT / item["path"]
        if not path.is_file():
            errors.append(f"missing port: {item['path']}")
            continue
        source = path.read_text()
        if item["symbol"] not in source:
            errors.append(f"missing exported symbol {item['symbol']}: {item['path']}")
        if item.get("name") == "C++":
            if "../../c/p/planar_embedding_lr.c" in source:
                errors.append("C++ port must not include the C kernel")
            if "std::array" not in source:
                errors.append("C++ port must own its bounded std::array implementation")

    workload_meta = inventory["workload"]
    workload_path = ROOT / workload_meta["path"]
    if not workload_path.is_file():
        errors.append(f"missing workload: {workload_meta['path']}")
        return errors
    workload = json.loads(workload_path.read_text())
    if (
        workload.get("algorithm") != "planar_embedding_lr"
        or workload.get("function_symbol") != "planar_embedding_lr"
        or workload.get("abi") != inventory.get("abi")
    ):
        errors.append("workload algorithm or ABI differs from the inventory")
    pinned_cases = workload_meta["valid_cases"]
    actual_cases = workload.get("cases", [])
    projection = [
        {
            "id": case.get("id"),
            "input_values": case.get("input_values"),
            "output_capacity": case.get("output_capacity"),
            "expected_status": case.get("expected_status"),
            "expected_result": case.get("expected_result"),
        }
        for case in actual_cases
    ]
    if projection != pinned_cases:
        errors.append("workload fixtures, expected statuses, or result lengths differ from inventory")
    if [case.get("id") for case in workload.get("invalid_cases", [])] != workload_meta["invalid_case_ids"]:
        errors.append("invalid workload fixture IDs differ from inventory")

    output_limit = workload.get("output", {}).get("maximum_output_bytes")
    if output_limit != 193 or workload.get("workspace", {}).get("bytes") != 193:
        errors.append("byte output/workspace limits must both be pinned at 193")
    if workload.get("output", {}).get("maximum_output_length") != output_limit:
        errors.append("maximum output length and byte limit disagree")
    fixed_workspace = workload.get("algorithm_details", {}).get("fixed_workspace_bytes_upper_bound")
    if fixed_workspace != 50208 or inventory.get("fixed_workspace_bytes_upper_bound") != fixed_workspace:
        errors.append("fixed internal table workspace differs from the pinned 50,208-byte bound")
    for case in actual_cases:
        values = case.get("input_values", [])
        if len(values) < 2 or case.get("input_length") != len(values):
            errors.append(f"invalid packed input length metadata: {case.get('id')}")
            continue
        edge_count = values[1]
        status = case.get("expected_status")
        expected_result = 1 if status == 0 else 1 + 2 * edge_count if status == 1 else None
        if expected_result is None or case.get("expected_result") != expected_result:
            errors.append(f"status/result length contract mismatch: {case.get('id')}")
        elif isinstance(output_limit, int) and expected_result > output_limit:
            errors.append(f"result length exceeds output capacity: {case.get('id')}")
        if expected_result is not None and (
            not isinstance(case.get("output_capacity"), int)
            or case["output_capacity"] < expected_result
        ):
            errors.append(f"fixture output capacity is too small: {case.get('id')}")
    return errors


if __name__ == "__main__":  # pragma: no cover - static review entry point
    for error in inventory_errors():
        print(error)
