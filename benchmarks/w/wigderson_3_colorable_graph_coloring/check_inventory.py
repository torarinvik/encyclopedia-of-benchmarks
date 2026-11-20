"""Static package-inventory review; this is not a test runner."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "wigderson_3_colorable_graph_coloring"
EXPECTED_LANGUAGES = [
    ("C", "c/t/wigderson_3_colorable_graph_coloring.c"),
    ("C3", "c3/t/wigderson_3_colorable_graph_coloring.c3"),
    ("C++", "cpp/t/wigderson_3_colorable_graph_coloring.cpp"),
    ("Elisa", "elisa/t/wigderson_3_colorable_graph_coloring.elisa"),
    ("Mojo", "mojo/t/wigderson_3_colorable_graph_coloring.mojo"),
    ("Nim", "nim/t/wigderson_3_colorable_graph_coloring.nim"),
    ("Odin", "odin/t/wigderson_3_colorable_graph_coloring.odin"),
    ("Rust", "rust/t/wigderson_3_colorable_graph_coloring.rs"),
    ("V", "v/t/wigderson_3_colorable_graph_coloring.v"),
    ("Zig", "zig/t/wigderson_3_colorable_graph_coloring.zig"),
]


def inventory_errors() -> list[str]:
    inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    if inventory.get("algorithm") != SYMBOL or inventory.get("abi") != "i64_array_bytes_output":
        errors.append("algorithm or ABI differs from the package contract")
    languages = inventory.get("languages", [])
    if [(item.get("name"), item.get("path")) for item in languages] != EXPECTED_LANGUAGES:
        errors.append("language names or source paths differ from the ten-port inventory")
    for item in languages:
        if item.get("symbol") != SYMBOL:
            errors.append(f"unexpected symbol in inventory: {item.get('path')}")
        path = ROOT / item["path"]
        if not path.is_file():
            errors.append(f"missing port: {item['path']}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"exported symbol is missing: {item['path']}")

    workload_meta = inventory.get("workload", {})
    workload_path = ROOT / workload_meta.get("path", "")
    if not workload_path.is_file():
        errors.append("workload file is missing")
        return errors
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != inventory.get("abi")):
        errors.append("workload algorithm, symbol, or ABI differs from inventory")
    valid_cases = workload.get("cases", [])
    projection = [
        {key: case.get(key) for key in
         ("id", "input_values", "output_capacity", "expected_result", "expected_output_hex")}
        for case in valid_cases
    ]
    if projection != workload_meta.get("valid_cases"):
        errors.append("valid workload fixtures differ from the inventory projection")
    if [case.get("id") for case in workload.get("invalid_cases", [])] != workload_meta.get("invalid_case_ids"):
        errors.append("invalid-case identifiers differ from the inventory")
    if [case.get("id") for case in workload.get("capacity_cases", [])] != workload_meta.get("capacity_case_ids"):
        errors.append("capacity-case identifiers differ from the inventory")
    if workload.get("output", {}).get("maximum_bytes") != 33:
        errors.append("maximum output must be 33 bytes")
    if workload.get("workspace", {}).get("bytes") != 2048 or inventory.get("fixed_workspace_bytes_upper_bound") != 2048:
        errors.append("workspace bound must be 2,048 bytes")
    for case in valid_cases:
        values = case.get("input_values", [])
        output_hex = case.get("expected_output_hex", "")
        if len(output_hex) % 2 or len(bytes.fromhex(output_hex)) != case.get("expected_result"):
            errors.append(f"output length does not match the fixture result: {case.get('id')}")
        if case.get("input_length") != len(values):
            errors.append(f"input length metadata differs: {case.get('id')}")
        if case.get("output_capacity", 0) < case.get("expected_result", 0):
            errors.append(f"output capacity is insufficient: {case.get('id')}")
    return errors


if __name__ == "__main__":  # pragma: no cover
    for error in inventory_errors():
        print(error)
