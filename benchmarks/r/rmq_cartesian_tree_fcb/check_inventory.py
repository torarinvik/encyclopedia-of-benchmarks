"""Non-executing inventory inspection for the RMQ package."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/rmq_cartesian_tree_fcb"
SYMBOL = "rmq_cartesian_tree_fcb"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
    "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig",
}
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
)


def inspect_inventory() -> list[str]:
    issues = [f"missing package artifact: {name}" for name in ARTIFACTS
              if not (PACKAGE / name).is_file()]
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "r" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language} port")
    return issues


def static_issues() -> list[str]:
    """Return source inventory problems without running workload or ports."""
    return inspect_inventory()
