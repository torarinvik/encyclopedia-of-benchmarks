"""Static package-artifact and ten-port inventory."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "sqrt_tree_constant_time"
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PORTS = (
    "c/s/sqrt_tree_constant_time.c", "c3/s/sqrt_tree_constant_time.c3",
    "cpp/s/sqrt_tree_constant_time.cpp", "elisa/s/sqrt_tree_constant_time.elisa",
    "mojo/s/sqrt_tree_constant_time.mojo", "nim/s/sqrt_tree_constant_time.nim",
    "odin/s/sqrt_tree_constant_time.odin", "rust/s/sqrt_tree_constant_time.rs",
    "v/s/sqrt_tree_constant_time.v", "zig/s/sqrt_tree_constant_time.zig",
)


def static_issues() -> list[str]:
    """Report missing package artifacts and unfinished or absent port sources."""
    issues: list[str] = []
    for relative in ARTIFACTS:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port source: {relative}")
            continue
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read port source {relative}: {error}")
            continue
        if SYMBOL not in source or re.search(r"\bTODO\b|PLACEHOLDER", source):
            issues.append(f"missing symbol or unfinished port: {relative}")
    return issues


def inspect_inventory() -> tuple[int, int]:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))
    return len(PORTS), len(ARTIFACTS)
