"""Static package inventory API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/m/miller_backward_recurrence_normalization.c",
    "c3/m/miller_backward_recurrence_normalization.c3",
    "cpp/m/miller_backward_recurrence_normalization.cpp",
    "elisa/m/miller_backward_recurrence_normalization.elisa",
    "mojo/m/miller_backward_recurrence_normalization.mojo",
    "nim/m/miller_backward_recurrence_normalization.nim",
    "odin/m/miller_backward_recurrence_normalization.odin",
    "rust/m/miller_backward_recurrence_normalization.rs",
    "v/m/miller_backward_recurrence_normalization.v",
    "zig/m/miller_backward_recurrence_normalization.zig",
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
    if inventory.get("algorithm") != "miller_backward_recurrence_normalization":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if inventory.get("source") != "https://dlmf.nist.gov/3.6.iii":
        issues.append("inventory source differs")
    if inventory.get("workspace", {}).get("bytes") != 192:
        issues.append("inventory workspace differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "miller_backward_recurrence_normalization" not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
        if relative.split("/")[-1] not in readme:
            issues.append(f"README omits port filename: {relative}")
    elisa_path = ROOT / "elisa/m/miller_backward_recurrence_normalization.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa implementation must use bounded input/output views")
        if "def miller_prepare(input: view[i64], result_words: mutable view[i64])" not in source:
            issues.append("Elisa recurrence helper must operate on bounded views")
        if "def miller_impl(input: view[i64], output: mutable u8&" in source:
            issues.append("Elisa ABI output reference must not flow into the recurrence helper")
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
