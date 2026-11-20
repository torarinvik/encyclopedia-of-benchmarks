"""Static package inventory helper; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "k_repetition_binary_division_kernel"
EXPECTED_SOURCES = {
    "c/k/k_repetition_binary_division_kernel.c",
    "c3/k/k_repetition_binary_division_kernel.c3",
    "cpp/k/k_repetition_binary_division_kernel.cpp",
    "elisa/k/k_repetition_binary_division_kernel.elisa",
    "mojo/k/k_repetition_binary_division_kernel.mojo",
    "nim/k/k_repetition_binary_division_kernel.nim",
    "odin/k/k_repetition_binary_division_kernel.odin",
    "rust/k/k_repetition_binary_division_kernel.rs",
    "v/k/k_repetition_binary_division_kernel.v",
    "zig/k/k_repetition_binary_division_kernel.zig",
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
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if input_meta.get("maximum_valid_length") != 2 + input_meta.get("n_range", [0, 0])[1]:
        issues.append("valid input bound does not match [n,K,text...] framing")
    if input_meta.get("maximum_parseable_length") != input_meta.get("maximum_valid_length", 0) + 1:
        issues.append("parseable input bound does not include exactly one trailing probe")
    n = input_meta.get("n_range", [0, 0])[1]
    expected_records = sum((n - 2 * period + 1) * (n - 2 * period + 2) // 2
                           for period in range(1, n // 2 + 1))
    if output_meta.get("maximum_records") != expected_records:
        issues.append("maximum record count differs from the start/end/period domain")
    if output_meta.get("maximum_output_bytes") != 8 + expected_records * 32:
        issues.append("maximum output bytes differ from the record bound")
    if not workload.get("cases"):
        issues.append("workload has no fixtures")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
