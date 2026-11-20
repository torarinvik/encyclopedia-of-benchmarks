"""Package-local static inventory checks; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/l/levin_partial_sum_transform.c",
    "c3/l/levin_partial_sum_transform.c3",
    "cpp/l/levin_partial_sum_transform.cpp",
    "elisa/l/levin_partial_sum_transform.elisa",
    "mojo/l/levin_partial_sum_transform.mojo",
    "nim/l/levin_partial_sum_transform.nim",
    "odin/l/levin_partial_sum_transform.odin",
    "rust/l/levin_partial_sum_transform.rs",
    "v/l/levin_partial_sum_transform.v",
    "zig/l/levin_partial_sum_transform.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "__init__.py", "workload.json",
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
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "levin_partial_sum_transform":
        issues.append("inventory algorithm identity differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        elif "levin_partial_sum_transform" not in source.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
        if relative not in readme:
            issues.append(f"README omits path: {relative}")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing inventory API; this helper is intentionally not run here."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
