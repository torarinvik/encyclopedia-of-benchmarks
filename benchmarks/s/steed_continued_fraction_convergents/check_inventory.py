"""Static package inventory API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/s/steed_continued_fraction_convergents.c",
    "c3/s/steed_continued_fraction_convergents.c3",
    "cpp/s/steed_continued_fraction_convergents.cpp",
    "elisa/s/steed_continued_fraction_convergents.elisa",
    "mojo/s/steed_continued_fraction_convergents.mojo",
    "nim/s/steed_continued_fraction_convergents.nim",
    "odin/s/steed_continued_fraction_convergents.odin",
    "rust/s/steed_continued_fraction_convergents.rs",
    "v/s/steed_continued_fraction_convergents.v",
    "zig/s/steed_continued_fraction_convergents.zig",
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
    if inventory.get("algorithm") != "steed_continued_fraction_convergents":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if inventory.get("source") != "https://dlmf.nist.gov/3.10#E16":
        issues.append("inventory source differs")
    if inventory.get("workspace", {}).get("bytes") != 0:
        issues.append("inventory workspace differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "steed_continued_fraction_convergents" not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
        if relative not in readme:
            issues.append(f"README omits path: {relative}")
    elisa_path = ROOT / "elisa/s/steed_continued_fraction_convergents.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa implementation must use bounded input/output views")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa raw-pointer types must stay at the exported ABI boundary")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing static inventory API; intentionally not run here."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
