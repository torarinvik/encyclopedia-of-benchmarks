"""Static file and language-port inventory; does not execute project code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "flood_fill_breadth_first"
PORTS = {
    "C": "c/f/flood_fill_breadth_first.c",
    "C3": "c3/f/flood_fill_breadth_first.c3",
    "C++": "cpp/f/flood_fill_breadth_first.cpp",
    "Elisa": "elisa/f/flood_fill_breadth_first.elisa",
    "Mojo": "mojo/f/flood_fill_breadth_first.mojo",
    "Nim": "nim/f/flood_fill_breadth_first.nim",
    "Odin": "odin/f/flood_fill_breadth_first.odin",
    "Rust": "rust/f/flood_fill_breadth_first.rs",
    "V": "v/f/flood_fill_breadth_first.v",
    "Zig": "zig/f/flood_fill_breadth_first.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "RESERVATION.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
    "inventory.json",
)


def static_issues() -> list[str]:
    issues = [f"missing package artifact: {name}" for name in REQUIRED
              if not (PACKAGE / name).is_file()]
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package inventory: {error}"]
    if (len(PORTS) != 10 or set(inventory.get("languages", {}))
            != {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}):
        issues.append("inventory does not enumerate the ten supported languages")
    if "clean-room" not in rights or "Algorithm Archive" not in rights:
        issues.append("rights note omits provenance and independent-implementation scope")
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if STEM not in source:
            issues.append(f"export symbol missing from {relative}")
        if relative not in readme:
            issues.append(f"README source link mismatch for {relative}")
    return issues
