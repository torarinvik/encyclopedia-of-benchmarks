"""Static file and port inventory check; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/c/consistent_overhead_byte_stuffing.c",
    "c3/c/consistent_overhead_byte_stuffing.c3",
    "cpp/c/consistent_overhead_byte_stuffing.cpp",
    "elisa/c/consistent_overhead_byte_stuffing.elisa",
    "mojo/c/consistent_overhead_byte_stuffing.mojo",
    "nim/c/consistent_overhead_byte_stuffing.nim",
    "odin/c/consistent_overhead_byte_stuffing.odin",
    "rust/c/consistent_overhead_byte_stuffing.rs",
    "v/c/consistent_overhead_byte_stuffing.v",
    "zig/c/consistent_overhead_byte_stuffing.zig",
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
    if (inventory.get("algorithm") != "consistent_overhead_byte_stuffing"
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("function_symbol") != "consistent_overhead_byte_stuffing"
            or inventory.get("ports") != list(PORTS)):
        issues.append("inventory identity or port list differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "consistent_overhead_byte_stuffing" not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol absent: {relative}")
        if relative not in readme:
            issues.append(f"README omits port path: {relative}")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
