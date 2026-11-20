"""Static source, workload, and package inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .verify_workload import workload_issues
except ImportError:
    from verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "k_subset_colex_rank_unrank"
PORTS = {
    "c": "c/k/k_subset_colex_rank_unrank.c",
    "c3": "c3/k/k_subset_colex_rank_unrank.c3",
    "cpp": "cpp/k/k_subset_colex_rank_unrank.cpp",
    "elisa": "elisa/k/k_subset_colex_rank_unrank.elisa",
    "mojo": "mojo/k/k_subset_colex_rank_unrank.mojo",
    "nim": "nim/k/k_subset_colex_rank_unrank.nim",
    "odin": "odin/k/k_subset_colex_rank_unrank.odin",
    "rust": "rust/k/k_subset_colex_rank_unrank.rs",
    "v": "v/k/k_subset_colex_rank_unrank.v",
    "zig": "zig/k/k_subset_colex_rank_unrank.zig",
}


def check_inventory() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory_text = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("maximum_valid_input_words") != 19
            or inventory.get("maximum_parseable_input_words") != 20
            or inventory.get("maximum_output_bytes") != 136
            or inventory.get("workspace_bytes") != 1024):
        issues.append("inventory bounds or identity differ")
    if set(inventory.get("sources", ())) != set(PORTS.values()):
        issues.append("inventory source list differs from ten ports")
    for source in ("Combinatorial Algorithms", "2.3.2"):
        if source not in readme or source not in rights:
            issues.append(f"primary citation missing: {source}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload identity or ABI differs")
    for relative in PORTS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing source: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"symbol missing: {relative}")
        if relative not in inventory_text:
            issues.append(f"INVENTORY.md omits: {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README omits: {relative}")
    if not isinstance(workload.get("workspace"), dict) or workload["workspace"].get("bytes") != 1024:
        issues.append("workload workspace bound differs")
    issues.extend(workload_issues())
    return issues


static_issues = check_inventory
