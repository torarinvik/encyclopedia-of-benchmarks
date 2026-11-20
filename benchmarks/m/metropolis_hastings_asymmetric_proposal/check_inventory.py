"""Static package inventory reviewer; this file does not execute the ports."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
EXPECTED_LANGUAGES = [
    ("C", "c/m/metropolis_hastings_asymmetric_proposal.c"),
    ("C3", "c3/m/metropolis_hastings_asymmetric_proposal.c3"),
    ("C++", "cpp/m/metropolis_hastings_asymmetric_proposal.cpp"),
    ("Elisa", "elisa/m/metropolis_hastings_asymmetric_proposal.elisa"),
    ("Mojo", "mojo/m/metropolis_hastings_asymmetric_proposal.mojo"),
    ("Nim", "nim/m/metropolis_hastings_asymmetric_proposal.nim"),
    ("Odin", "odin/m/metropolis_hastings_asymmetric_proposal.odin"),
    ("Rust", "rust/m/metropolis_hastings_asymmetric_proposal.rs"),
    ("V", "v/m/metropolis_hastings_asymmetric_proposal.v"),
    ("Zig", "zig/m/metropolis_hastings_asymmetric_proposal.zig"),
]


def inventory_errors() -> list[str]:
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    errors: list[str] = []
    for document in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / document).is_file():
            errors.append(f"missing package artifact: {document}")
    if inventory.get("algorithm") != "metropolis_hastings_asymmetric_proposal":
        errors.append("inventory algorithm does not match the package")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI does not match the package")
    languages = inventory.get("languages", [])
    if [(item.get("name"), item.get("path")) for item in languages] != EXPECTED_LANGUAGES:
        errors.append("language paths do not match the pinned ten-port inventory")
    for item in languages:
        if item.get("symbol") != "metropolis_hastings_asymmetric_proposal":
            errors.append(f"unexpected symbol in inventory: {item.get('path')}")
        path = ROOT / item["path"]
        if not path.is_file():
            errors.append(f"missing port: {item['path']}")
        elif item["symbol"] not in path.read_text():
            errors.append(f"missing exported symbol {item['symbol']}: {item['path']}")

    workload_path = ROOT / inventory["workload_path"]
    if not workload_path.is_file():
        errors.append(f"missing workload: {inventory['workload_path']}")
        return errors
    workload = json.loads(workload_path.read_text())
    if workload.get("algorithm") != inventory.get("algorithm") or workload.get("abi") != inventory.get("abi"):
        errors.append("workload algorithm or ABI differs from inventory")
    expected_cases = [
        {
            "id": case.get("id"),
            "input_values": case.get("input_values"),
            "input_length": case.get("input_length"),
            "input_is_null": case.get("input_is_null", False),
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "expected_result": case.get("expected_result"),
            "expected_output_hex": case.get("expected_output_hex"),
        }
        for case in workload.get("cases", [])
    ]
    pinned_cases = [
        {
            **case,
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
        }
        for case in inventory.get("cases", [])
    ]
    if expected_cases != pinned_cases:
        errors.append("workload fixture inputs/results differ from inventory")
    if workload.get("input", {}).get("maximum_valid_length") != inventory.get("maximum_input_length"):
        errors.append("maximum input length differs from inventory")
    if workload.get("input", {}).get("maximum_parseable_length") != inventory.get("maximum_parseable_input_length"):
        errors.append("maximum parseable input length differs from inventory")
    if workload.get("output", {}).get("maximum_bytes") != inventory.get("maximum_output_bytes"):
        errors.append("maximum output length differs from inventory")
    if workload.get("workspace", {}).get("bytes") != inventory.get("workspace_bytes"):
        errors.append("staged workspace differs from inventory")
    if (workload.get("source", {}).get("discovery_url")
            != "https://www.algorithm-archive.org/contents/metropolis/metropolis.html"
            or workload.get("source", {}).get("algorithm_url")
            != "https://doi.org/10.1093/biomet/57.1.97"):
        errors.append("source provenance differs from the pinned discovery and primary sources")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            errors.append(f"input length metadata mismatch: {case.get('id')}")
        result = case.get("expected_result")
        if result >= 0 and len(bytes.fromhex(case.get("expected_output_hex", ""))) != result:
            errors.append(f"expected output length mismatch: {case.get('id')}")
    return errors


if __name__ == "__main__":  # pragma: no cover - static review entry point
    for error in inventory_errors():
        print(error)
