"""Static package inventory API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/f/fornberg_finite_difference_weights.c",
    "c3/f/fornberg_finite_difference_weights.c3",
    "cpp/f/fornberg_finite_difference_weights.cpp",
    "elisa/f/fornberg_finite_difference_weights.elisa",
    "mojo/f/fornberg_finite_difference_weights.mojo",
    "nim/f/fornberg_finite_difference_weights.nim",
    "odin/f/fornberg_finite_difference_weights.odin",
    "rust/f/fornberg_finite_difference_weights.rs",
    "v/f/fornberg_finite_difference_weights.v",
    "zig/f/fornberg_finite_difference_weights.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "__init__.py",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py",
)
ALGORITHM = "fornberg_finite_difference_weights"


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
    if inventory.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port list differs")
    if inventory.get("source") != "https://doi.org/10.1090/S0025-5718-1988-0935077-0":
        issues.append("inventory primary source differs")
    if inventory.get("workspace", {}).get("bytes") != 512:
        issues.append("native workspace bound differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"export marker missing: {relative}")
        if relative.rsplit("/", 1)[-1] not in readme:
            issues.append(f"README omits source filename: {relative}")
    elisa_path = ROOT / "elisa/f/fornberg_finite_difference_weights.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa internals should use bounded input/output views")
        helper_source = source.split("@export", 1)[0]
        if "UnsafePointer[" in helper_source:
            issues.append("Elisa raw-pointer types must remain at the exported ABI boundary")
        if "fn fornberg_compute(input: view[i64], result_words: mutable view[i64])" not in source:
            issues.append("Elisa recurrence helper must consume bounded views")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing static inventory API; this helper is intentionally not run."""
    return static_issues()


if __name__ == "__main__":
    inventory_issues = check_inventory()
    if inventory_issues:
        raise SystemExit("\n".join(inventory_issues))
