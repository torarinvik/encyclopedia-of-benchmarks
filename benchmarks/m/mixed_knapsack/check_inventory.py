"""Static package-artifact and ten-port inventory."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "mixed_knapsack"
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PORTS = (
    "c/m/mixed_knapsack.c", "c3/m/mixed_knapsack.c3",
    "cpp/m/mixed_knapsack.cpp", "elisa/m/mixed_knapsack.elisa",
    "mojo/m/mixed_knapsack.mojo", "nim/m/mixed_knapsack.nim",
    "odin/m/mixed_knapsack.odin", "rust/m/mixed_knapsack.rs",
    "v/m/mixed_knapsack.v", "zig/m/mixed_knapsack.zig",
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
