"""Static source and metadata inventory helper; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "k_mismatch_longest_extension_table"
EXPECTED_SOURCES = {
    "c/k/k_mismatch_longest_extension_table.c",
    "c3/k/k_mismatch_longest_extension_table.c3",
    "cpp/k/k_mismatch_longest_extension_table.cpp",
    "elisa/k/k_mismatch_longest_extension_table.elisa",
    "mojo/k/k_mismatch_longest_extension_table.mojo",
    "nim/k/k_mismatch_longest_extension_table.nim",
    "odin/k/k_mismatch_longest_extension_table.odin",
    "rust/k/k_mismatch_longest_extension_table.rs",
    "v/k/k_mismatch_longest_extension_table.v",
    "zig/k/k_mismatch_longest_extension_table.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ["inventory or workload is unreadable or invalid JSON"]
    if inventory.get("algorithm") != ALGORITHM or workload.get("algorithm") != ALGORITHM:
        issues.append("algorithm ID differs from package name")
    if inventory.get("abi") != "i64_array_bytes_output" or workload.get("abi") != inventory.get("abi"):
        issues.append("ABI differs between inventory and workload")
    if set(inventory.get("sources", [])) != EXPECTED_SOURCES:
        issues.append("inventory does not list exactly the ten supported sources")
    for relative in EXPECTED_SOURCES:
        if not (ROOT / relative).is_file():
            issues.append(f"missing language source: {relative}")
    for relative in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file: {relative}")
    for section, field, inventory_field in (
        ("input", "maximum_valid_length", "maximum_valid_input_words"),
        ("input", "maximum_parseable_length", "maximum_parseable_input_words"),
        ("output", "maximum_output_bytes", "maximum_output_bytes"),
        ("workspace", "bytes", "workspace_bytes"),
    ):
        if workload.get(section, {}).get(field) != inventory.get(inventory_field):
            issues.append(f"{section}.{field} differs from inventory")
    if not workload.get("cases"):
        issues.append("workload has no fixtures")
    if workload.get("input", {}).get("maximum_valid_length") != 2 + workload["input"]["n_range"][1]:
        issues.append("valid input bound does not match [n,K,text...] framing")
    if workload.get("output", {}).get("maximum_output_bytes") != workload["input"]["n_range"][1] * (workload["input"]["K_range"][1] + 1):
        issues.append("output bound does not match n*(K+1)")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
