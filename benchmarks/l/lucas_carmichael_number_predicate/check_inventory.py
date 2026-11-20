"""Static package inventory check; intentionally unrun."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/l/lucas_carmichael_number_predicate.c",
    "c3/l/lucas_carmichael_number_predicate.c3",
    "cpp/l/lucas_carmichael_number_predicate.cpp",
    "elisa/l/lucas_carmichael_number_predicate.elisa",
    "mojo/l/lucas_carmichael_number_predicate.mojo",
    "nim/l/lucas_carmichael_number_predicate.nim",
    "odin/l/lucas_carmichael_number_predicate.odin",
    "rust/l/lucas_carmichael_number_predicate.rs",
    "v/l/lucas_carmichael_number_predicate.v",
    "zig/l/lucas_carmichael_number_predicate.zig",
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
    if (inventory.get("algorithm") != "lucas_carmichael_number_predicate"
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("function_symbol") != "lucas_carmichael_number_predicate"
            or inventory.get("ports") != list(PORTS)):
        issues.append("inventory identity or port list differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "lucas_carmichael_number_predicate" not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol absent: {relative}")
        if relative not in readme:
            issues.append(f"README omits source path: {relative}")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
