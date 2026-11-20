"""Static package inventory helper; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "markov_normal_string_rewriting"
EXPECTED_SOURCES = {
    "c/m/markov_normal_string_rewriting.c",
    "c3/m/markov_normal_string_rewriting.c3",
    "cpp/m/markov_normal_string_rewriting.cpp",
    "elisa/m/markov_normal_string_rewriting.elisa",
    "mojo/m/markov_normal_string_rewriting.mojo",
    "nim/m/markov_normal_string_rewriting.nim",
    "odin/m/markov_normal_string_rewriting.odin",
    "rust/m/markov_normal_string_rewriting.rs",
    "v/m/markov_normal_string_rewriting.v",
    "zig/m/markov_normal_string_rewriting.zig",
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
        ("output", "maximum_bytes", "maximum_output_bytes"),
        ("workspace", "bytes", "workspace_bytes"),
    ):
        if workload.get(section, {}).get(field) != inventory.get(inventory_field):
            issues.append(f"{section}.{field} differs from inventory")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    expected_valid = (
        3 + input_meta.get("initial_word_length_range", [0, 0])[1]
        + input_meta.get("rule_count_range", [0, 0])[1]
        * (3 + input_meta.get("rule_side_length_range", {}).get("lhs", [0, 0])[1]
           + input_meta.get("rule_side_length_range", {}).get("rhs", [0, 0])[1])
    )
    if input_meta.get("maximum_valid_length") != expected_valid:
        issues.append("valid input bound differs from maximum rule/word framing")
    if input_meta.get("maximum_parseable_length") != expected_valid + 1:
        issues.append("parseable input bound does not include one trailing probe")
    if output_meta.get("maximum_bytes") != 3 + workload.get("contract", {}).get("intermediate_word_limit", 0):
        issues.append("output cap differs from the framed maximum word")
    if not workload.get("cases"):
        issues.append("workload has no fixtures")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
