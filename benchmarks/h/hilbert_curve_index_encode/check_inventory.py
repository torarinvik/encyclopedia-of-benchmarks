"""Static inventory API for the bounded Hilbert-index package."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/h/hilbert_curve_index_encode.c",
    "c3/h/hilbert_curve_index_encode.c3",
    "cpp/h/hilbert_curve_index_encode.cpp",
    "elisa/h/hilbert_curve_index_encode.elisa",
    "mojo/h/hilbert_curve_index_encode.mojo",
    "nim/h/hilbert_curve_index_encode.nim",
    "odin/h/hilbert_curve_index_encode.odin",
    "rust/h/hilbert_curve_index_encode.rs",
    "v/h/hilbert_curve_index_encode.v",
    "zig/h/hilbert_curve_index_encode.zig",
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
    if inventory.get("algorithm") != "hilbert_curve_index_encode":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port paths differ")
    if inventory.get("source") != "https://doi.org/10.1109/T-C.1971.223258":
        issues.append("inventory source differs")
    if inventory.get("workspace", {}).get("bytes") != 0:
        issues.append("inventory workspace differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "hilbert_curve_index_encode" not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
        if relative not in readme:
            issues.append(f"README omits path: {relative}")
    elisa_path = ROOT / "elisa/h/hilbert_curve_index_encode.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa implementation must use bounded input/output views")
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
