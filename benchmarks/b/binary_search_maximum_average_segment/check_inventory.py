"""Static file and ABI inventory; this module is intentionally not auto-run."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "binary_search_maximum_average_segment"
PORTS = (
    "c/b/binary_search_maximum_average_segment.c",
    "c3/b/binary_search_maximum_average_segment.c3",
    "cpp/b/binary_search_maximum_average_segment.cpp",
    "elisa/b/binary_search_maximum_average_segment.elisa",
    "mojo/b/binary_search_maximum_average_segment.mojo",
    "nim/b/binary_search_maximum_average_segment.nim",
    "odin/b/binary_search_maximum_average_segment.odin",
    "rust/b/binary_search_maximum_average_segment.rs",
    "v/b/binary_search_maximum_average_segment.v",
    "zig/b/binary_search_maximum_average_segment.zig",
)
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)


def inspect_inventory() -> tuple[int, int]:
    for relative in ARTIFACTS:
        if not (PACKAGE / relative).is_file():
            raise ValueError(f"missing package artifact: {relative}")
    for relative in PORTS:
        path = ROOT / relative
        text = path.read_text(encoding="utf-8")
        if SYMBOL not in text or re.search(r"\bTODO\b|PLACEHOLDER", text):
            raise ValueError(f"missing symbol or unfinished port: {relative}")
    return len(PORTS), len(ARTIFACTS)
