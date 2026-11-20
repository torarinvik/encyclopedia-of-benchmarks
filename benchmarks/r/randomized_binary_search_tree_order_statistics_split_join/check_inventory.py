"""Static file/provenance inventory; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "randomized_binary_search_tree_order_statistics_split_join"
PORTS = {
    "c": "c/r/randomized_binary_search_tree_order_statistics_split_join.c",
    "c3": "c3/r/randomized_binary_search_tree_order_statistics_split_join.c3",
    "cpp": "cpp/r/randomized_binary_search_tree_order_statistics_split_join.cpp",
    "elisa": "elisa/r/randomized_binary_search_tree_order_statistics_split_join.elisa",
    "mojo": "mojo/r/randomized_binary_search_tree_order_statistics_split_join.mojo",
    "nim": "nim/r/randomized_binary_search_tree_order_statistics_split_join.nim",
    "odin": "odin/r/randomized_binary_search_tree_order_statistics_split_join.odin",
    "rust": "rust/r/randomized_binary_search_tree_order_statistics_split_join.rs",
    "v": "v/r/randomized_binary_search_tree_order_statistics_split_join.v",
    "zig": "zig/r/randomized_binary_search_tree_order_statistics_split_join.zig",
}
SOURCES = (
    "https://doi.org/10.1145/274787.274812",
    "https://isa-afp.org/entries/Randomised_BSTs.html",
    "https://github.com/suisen-cp/java_competitive_programming_library",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read static package metadata: {error}"]
    for language, relative in PORTS.items():
        port = ROOT / relative
        if not port.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if SYMBOL not in port.read_text(encoding="utf-8"):
            issues.append(f"export symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
        if relative not in inventory:
            issues.append(f"inventory entry missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_result" not in (PACKAGE / name).read_text(encoding="utf-8"):
            issues.append(f"expected-result reference missing from {name}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("workload algorithm or ABI metadata mismatch")
    if len(workload.get("cases", [])) < 10:
        issues.append("workload has fewer than ten static cases")
    return issues
