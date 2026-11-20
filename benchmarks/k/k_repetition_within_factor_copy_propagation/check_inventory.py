"""Static package inventory helper; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "k_repetition_within_factor_copy_propagation"
EXPECTED_SOURCES = {
    "c/k/k_repetition_within_factor_copy_propagation.c",
    "c3/k/k_repetition_within_factor_copy_propagation.c3",
    "cpp/k/k_repetition_within_factor_copy_propagation.cpp",
    "elisa/k/k_repetition_within_factor_copy_propagation.elisa",
    "mojo/k/k_repetition_within_factor_copy_propagation.mojo",
    "nim/k/k_repetition_within_factor_copy_propagation.nim",
    "odin/k/k_repetition_within_factor_copy_propagation.odin",
    "rust/k/k_repetition_within_factor_copy_propagation.rs",
    "v/k/k_repetition_within_factor_copy_propagation.v",
    "zig/k/k_repetition_within_factor_copy_propagation.zig",
}


def static_issues() -> list[str]:
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ["inventory or workload is unreadable or invalid JSON"]
    issues: list[str] = []
    if inventory.get("algorithm") != ALGORITHM or workload.get("algorithm") != ALGORITHM:
        issues.append("algorithm ID differs from package name")
    if inventory.get("abi") != "i64_array_bytes_output" or workload.get("abi") != inventory.get("abi"):
        issues.append("ABI differs between inventory and workload")
    if set(inventory.get("sources", [])) != EXPECTED_SOURCES:
        issues.append("inventory does not list exactly the ten supported sources")
    for source in EXPECTED_SOURCES:
        if not (ROOT / source).is_file():
            issues.append(f"missing language source: {source}")
    for artifact in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package file: {artifact}")
    for section, field, inventory_field in (
        ("input", "maximum_valid_length", "maximum_valid_input_words"),
        ("input", "maximum_parseable_length", "maximum_parseable_input_words"),
        ("output", "maximum_output_bytes", "maximum_output_bytes"),
        ("workspace", "bytes", "workspace_bytes"),
    ):
        if workload.get(section, {}).get(field) != inventory.get(inventory_field):
            issues.append(f"{section}.{field} differs from inventory")
    n = workload.get("input", {}).get("n_range", [0, 0])[1]
    maximum_factors = workload.get("input", {}).get("factor_count_range", [0, 0])[1]
    maximum_seeds = workload.get("input", {}).get("seed_count_range", [0, 0])[1]
    if workload.get("input", {}).get("maximum_valid_length") != n + 4 + 3 * maximum_factors + 4 * maximum_seeds:
        issues.append("maximum input bound differs from frame/count bounds")
    if workload.get("input", {}).get("maximum_parseable_length") != n + 4 + 3 * maximum_factors + 4 * maximum_seeds + 1:
        issues.append("maximum parseable bound is not one trailing word beyond maximum frame")
    records = sum((n - 2 * period + 1) * (n - 2 * period + 2) // 2
                  for period in range(1, n // 2 + 1))
    if workload.get("output", {}).get("maximum_records") != records:
        issues.append("maximum record count differs from interval/period domain")
    if workload.get("output", {}).get("maximum_output_bytes") != 8 + 32 * records:
        issues.append("maximum output bytes differ from record bound")
    if not workload.get("cases"):
        issues.append("workload has no cases")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()

