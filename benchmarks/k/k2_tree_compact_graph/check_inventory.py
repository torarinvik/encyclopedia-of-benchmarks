"""Static package inventory check; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    "c/k/k2_tree_compact_graph.c",
    "c3/k/k2_tree_compact_graph.c3",
    "cpp/k/k2_tree_compact_graph.cpp",
    "elisa/k/k2_tree_compact_graph.elisa",
    "mojo/k/k2_tree_compact_graph.mojo",
    "nim/k/k2_tree_compact_graph.nim",
    "odin/k/k2_tree_compact_graph.odin",
    "rust/k/k2_tree_compact_graph.rs",
    "v/k/k2_tree_compact_graph.v",
    "zig/k/k2_tree_compact_graph.zig",
}
PACKAGE_FILES = {
    "README.md",
    "RIGHTS.md",
    "INVENTORY.md",
    "INVENTORY.json",
    "workload.json",
    "primary_oracle.py",
    "independent_oracle.py",
    "verify_workload.py",
    "check_inventory.py",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "k2_tree_compact_graph":
        issues.append("inventory algorithm mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload algorithm mismatch")
    sources = inventory.get("languages", {})
    if set(sources.values()) != EXPECTED_SOURCES:
        issues.append("inventory does not name the ten expected source paths")
    for relative in sorted(EXPECTED_SOURCES):
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "k2_tree_compact_graph" not in source:
            issues.append(f"missing ABI symbol text: {relative}")
    for relative in sorted(PACKAGE_FILES):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    for key in ("primary_reference", "independent_reference", "workload_reconciliation", "static_inventory"):
        relative = inventory.get(key)
        if not isinstance(relative, str) or not (ROOT / relative).is_file():
            issues.append(f"missing inventory reference: {key}")
    input_contract = inventory.get("input", {})
    output_contract = inventory.get("output", {})
    if input_contract.get("maximum_valid_words") != 418:
        issues.append("inventory maximum valid frame mismatch")
    if input_contract.get("maximum_parseable_words") != 419:
        issues.append("inventory maximum parseable frame mismatch")
    if output_contract.get("maximum_bytes") != 1032:
        issues.append("inventory maximum output mismatch")
    if inventory.get("workspace_bytes") != 4096:
        issues.append("inventory workspace cap mismatch")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
