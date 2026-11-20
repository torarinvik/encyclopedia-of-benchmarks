"""Static package inventory helper; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "k_repetition_block_head_pair_pass"
EXPECTED_SOURCES = {
    "c/k/k_repetition_block_head_pair_pass.c",
    "c3/k/k_repetition_block_head_pair_pass.c3",
    "cpp/k/k_repetition_block_head_pair_pass.cpp",
    "elisa/k/k_repetition_block_head_pair_pass.elisa",
    "mojo/k/k_repetition_block_head_pair_pass.mojo",
    "nim/k/k_repetition_block_head_pair_pass.nim",
    "odin/k/k_repetition_block_head_pair_pass.odin",
    "rust/k/k_repetition_block_head_pair_pass.rs",
    "v/k/k_repetition_block_head_pair_pass.v",
    "zig/k/k_repetition_block_head_pair_pass.zig",
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
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if input_meta.get("maximum_valid_length") != 2 + input_meta.get("n_range", [0, 0])[1]:
        issues.append("valid input bound differs from [n,K,text...] framing")
    if input_meta.get("maximum_parseable_length") != input_meta.get("maximum_valid_length", 0) + 1:
        issues.append("parseable bound must be one word beyond maximum valid input")
    n = input_meta.get("n_range", [0, 0])[1]
    records = sum((n - 2 * p + 1) * (n - 2 * p + 2) // 2 for p in range(1, n // 2 + 1))
    if output_meta.get("maximum_records") != records:
        issues.append("record bound differs from all (start,end,period) triples")
    if output_meta.get("maximum_output_bytes") != 8 + records * 32:
        issues.append("output byte bound differs from record bound")
    if not workload.get("cases"):
        issues.append("workload has no cases")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
