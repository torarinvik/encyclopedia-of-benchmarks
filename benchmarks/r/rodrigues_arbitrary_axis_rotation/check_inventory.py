"""Package-local source inventory review; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/r/rodrigues_arbitrary_axis_rotation.c",
    "c3/r/rodrigues_arbitrary_axis_rotation.c3",
    "cpp/r/rodrigues_arbitrary_axis_rotation.cpp",
    "elisa/r/rodrigues_arbitrary_axis_rotation.elisa",
    "mojo/r/rodrigues_arbitrary_axis_rotation.mojo",
    "nim/r/rodrigues_arbitrary_axis_rotation.nim",
    "odin/r/rodrigues_arbitrary_axis_rotation.odin",
    "rust/r/rodrigues_arbitrary_axis_rotation.rs",
    "v/r/rodrigues_arbitrary_axis_rotation.v",
    "zig/r/rodrigues_arbitrary_axis_rotation.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json", "__init__.py",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for relative in REQUIRED:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file: {relative}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "rodrigues_arbitrary_axis_rotation":
        issues.append("inventory algorithm identity differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory source paths differ")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        elif "rodrigues_arbitrary_axis_rotation" not in source.read_text(encoding="utf-8"):
            issues.append(f"exported symbol absent from: {relative}")
        if relative not in readme:
            issues.append(f"README omits source link: {relative}")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
