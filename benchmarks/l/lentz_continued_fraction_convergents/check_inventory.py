"""Package-local static inventory checks; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/l/lentz_continued_fraction_convergents.c",
    "c3/l/lentz_continued_fraction_convergents.c3",
    "cpp/l/lentz_continued_fraction_convergents.cpp",
    "elisa/l/lentz_continued_fraction_convergents.elisa",
    "mojo/l/lentz_continued_fraction_convergents.mojo",
    "nim/l/lentz_continued_fraction_convergents.nim",
    "odin/l/lentz_continued_fraction_convergents.odin",
    "rust/l/lentz_continued_fraction_convergents.rs",
    "v/lentz_continued_fraction_convergents.v",
    "zig/l/lentz_continued_fraction_convergents.zig",
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
    if inventory.get("algorithm") != "lentz_continued_fraction_convergents":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if (inventory.get("input", {}).get("maximum_valid_length") != 18
            or inventory.get("input", {}).get("maximum_parseable_length") != 19
            or inventory.get("output", {}).get("maximum_bytes") != 80):
        issues.append("inventory framing or output bound differs")
    if (workload.get("algorithm") != inventory.get("algorithm")
            or workload.get("function_symbol") != inventory.get("function_symbol")
            or workload.get("abi") != inventory.get("abi")
            or workload.get("workspace", {}).get("bytes")
            != inventory.get("workspace", {}).get("bytes")):
        issues.append("workload and inventory identity/bounds differ")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "lentz_continued_fraction_convergents" not in source:
            issues.append(f"entrypoint marker missing: {relative}")
        if relative.startswith("elisa/") and "view[i64]" not in source:
            issues.append("Elisa port does not visibly use bounded views")
        if relative not in readme:
            issues.append(f"README omits port: {relative}")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing static inventory API; this helper is intentionally not run."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
