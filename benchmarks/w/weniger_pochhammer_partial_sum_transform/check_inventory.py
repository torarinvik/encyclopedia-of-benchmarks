"""Package-local static inventory APIs; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/w/weniger_pochhammer_partial_sum_transform.c",
    "c3/w/weniger_pochhammer_partial_sum_transform.c3",
    "cpp/w/weniger_pochhammer_partial_sum_transform.cpp",
    "elisa/w/weniger_pochhammer_partial_sum_transform.elisa",
    "mojo/w/weniger_pochhammer_partial_sum_transform.mojo",
    "nim/w/weniger_pochhammer_partial_sum_transform.nim",
    "odin/w/weniger_pochhammer_partial_sum_transform.odin",
    "rust/w/weniger_pochhammer_partial_sum_transform.rs",
    "v/w/weniger_pochhammer_partial_sum_transform.v",
    "zig/w/weniger_pochhammer_partial_sum_transform.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "__init__.py",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
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
    if inventory.get("algorithm") != "weniger_pochhammer_partial_sum_transform":
        issues.append("inventory algorithm identity differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if inventory.get("source") != "https://dlmf.nist.gov/3.9#E16":
        issues.append("inventory source differs")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        elif "weniger_pochhammer_partial_sum_transform" not in source.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
        if relative not in readme:
            issues.append(f"README omits path: {relative}")
    elisa_path = ROOT / "elisa/w/weniger_pochhammer_partial_sum_transform.elisa"
    if elisa_path.is_file():
        elisa_source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa_source or "mutable view[u8]" not in elisa_source:
            issues.append("Elisa implementation must use bounded input/output views")
        if "UnsafePointer" in elisa_source or "ptr " in elisa_source:
            issues.append("Elisa must keep raw-pointer types at the ABI boundary")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing inventory API; this helper is intentionally not run here."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
