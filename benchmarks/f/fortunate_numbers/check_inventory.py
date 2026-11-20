"""Package-local source inventory review; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/f/fortunate_numbers.c",
    "c3/f/fortunate_numbers.c3",
    "cpp/f/fortunate_numbers.cpp",
    "elisa/f/fortunate_numbers.elisa",
    "mojo/f/fortunate_numbers.mojo",
    "nim/f/fortunate_numbers.nim",
    "odin/f/fortunate_numbers.odin",
    "rust/f/fortunate_numbers.rs",
    "v/f/fortunate_numbers.v",
    "zig/f/fortunate_numbers.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json", "__init__.py",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != "fortunate_numbers" or inventory.get("ports") != list(PORTS):
        issues.append("inventory algorithm or port paths differ")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "fortunate_numbers" not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol absent: {relative}")
        if relative not in readme:
            issues.append(f"README omits port link: {relative}")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
