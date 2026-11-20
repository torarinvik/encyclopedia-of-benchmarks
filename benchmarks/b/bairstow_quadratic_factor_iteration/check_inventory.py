"""Package-local static inventory checks; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/b/bairstow_quadratic_factor_iteration.c",
    "c3/b/bairstow_quadratic_factor_iteration.c3",
    "cpp/b/bairstow_quadratic_factor_iteration.cpp",
    "elisa/b/bairstow_quadratic_factor_iteration.elisa",
    "mojo/b/bairstow_quadratic_factor_iteration.mojo",
    "nim/b/bairstow_quadratic_factor_iteration.nim",
    "odin/b/bairstow_quadratic_factor_iteration.odin",
    "rust/b/bairstow_quadratic_factor_iteration.rs",
    "v/b/bairstow_quadratic_factor_iteration.v",
    "zig/b/bairstow_quadratic_factor_iteration.zig",
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
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "bairstow_quadratic_factor_iteration":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if (inventory.get("input", {}).get("maximum_valid_length") != 13
            or inventory.get("input", {}).get("maximum_parseable_length") != 14
            or inventory.get("output", {}).get("maximum_bytes") != 88):
        issues.append("inventory framing or output bound differs")
    if (workload.get("algorithm") != inventory.get("algorithm")
            or workload.get("function_symbol") != inventory.get("function_symbol")
            or workload.get("abi") != inventory.get("abi")):
        issues.append("workload and inventory identity differ")
    if workload.get("workspace", {}).get("bytes") != inventory.get("workspace", {}).get("bytes"):
        issues.append("workload and inventory workspace differ")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        else:
            text = source.read_text(encoding="utf-8")
            if "bairstow_quadratic_factor_iteration" not in text:
                issues.append(f"entrypoint marker missing: {relative}")
            if relative.startswith("elisa/") and "view[i64]" not in text:
                issues.append("Elisa port does not visibly use a bounded input view")
        if relative not in readme:
            issues.append(f"README omits path: {relative}")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing static inventory API; intentionally not run here."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
