"""Static inventory check for the Wolstenholme-number package."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/w/wolstenholme_numbers.c",
    "c3/w/wolstenholme_numbers.c3",
    "cpp/w/wolstenholme_numbers.cpp",
    "elisa/w/wolstenholme_numbers.elisa",
    "mojo/w/wolstenholme_numbers.mojo",
    "nim/w/wolstenholme_numbers.nim",
    "odin/w/wolstenholme_numbers.odin",
    "rust/w/wolstenholme_numbers.rs",
    "v/w/wolstenholme_numbers.v",
    "zig/w/wolstenholme_numbers.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "__init__.py", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py",
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
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "wolstenholme_numbers":
        issues.append("inventory algorithm differs")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI differs")
    if inventory.get("function_symbol") != "wolstenholme_numbers":
        issues.append("inventory function symbol differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port list differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "wolstenholme_numbers" not in path.read_text(encoding="utf-8"):
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
