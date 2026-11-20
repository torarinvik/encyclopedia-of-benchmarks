"""Static package inventory API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/b/barycentric_lagrange_evaluation.c",
    "c3/b/barycentric_lagrange_evaluation.c3",
    "cpp/b/barycentric_lagrange_evaluation.cpp",
    "elisa/b/barycentric_lagrange_evaluation.elisa",
    "mojo/b/barycentric_lagrange_evaluation.mojo",
    "nim/b/barycentric_lagrange_evaluation.nim",
    "odin/b/barycentric_lagrange_evaluation.odin",
    "rust/b/barycentric_lagrange_evaluation.rs",
    "v/b/barycentric_lagrange_evaluation.v",
    "zig/b/barycentric_lagrange_evaluation.zig",
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
    if inventory.get("algorithm") != "barycentric_lagrange_evaluation":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if inventory.get("source") != "https://dlmf.nist.gov/3.3.i#E1":
        issues.append("inventory DLMF source differs")
    if inventory.get("workspace", {}).get("bytes") != 128:
        issues.append("inventory workspace differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "barycentric_lagrange_evaluation" not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
        if relative.rsplit("/", 1)[-1] not in readme:
            issues.append(f"README omits port filename: {relative}")
    elisa_path = ROOT / "elisa/b/barycentric_lagrange_evaluation.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source:
            issues.append("Elisa implementation must use bounded input views")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa raw-pointer types must stay at the exported ABI boundary")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing static inventory API; this helper is intentionally not run."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
