"""Static package artifact and ten-port inventory."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "bounded_knapsack_binary_grouping"
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PORTS = (
    "c/b/bounded_knapsack_binary_grouping.c",
    "c3/b/bounded_knapsack_binary_grouping.c3",
    "cpp/b/bounded_knapsack_binary_grouping.cpp",
    "elisa/b/bounded_knapsack_binary_grouping.elisa",
    "mojo/b/bounded_knapsack_binary_grouping.mojo",
    "nim/b/bounded_knapsack_binary_grouping.nim",
    "odin/b/bounded_knapsack_binary_grouping.odin",
    "rust/b/bounded_knapsack_binary_grouping.rs",
    "v/b/bounded_knapsack_binary_grouping.v",
    "zig/b/bounded_knapsack_binary_grouping.zig",
)


def inspect_inventory() -> tuple[int, int]:
    for relative in ARTIFACTS:
        if not (PACKAGE / relative).is_file():
            raise ValueError(f"missing package artifact: {relative}")
    for relative in PORTS:
        source = (ROOT / relative).read_text(encoding="utf-8")
        if SYMBOL not in source or re.search(r"\bTODO\b|PLACEHOLDER", source):
            raise ValueError(f"missing symbol or unfinished port: {relative}")
    return len(PORTS), len(ARTIFACTS)
