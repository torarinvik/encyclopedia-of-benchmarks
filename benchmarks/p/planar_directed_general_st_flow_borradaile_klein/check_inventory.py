"""Package completeness helper for the scalar/byte-output suite; not executed here."""
from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "planar_directed_general_st_flow_borradaile_klein"
PORTS = {
    "c": "c/p/planar_directed_general_st_flow_borradaile_klein.c",
    "c3": "c3/p/planar_directed_general_st_flow_borradaile_klein.c3",
    "cpp": "cpp/p/planar_directed_general_st_flow_borradaile_klein.cpp",
    "elisa": "elisa/p/planar_directed_general_st_flow_borradaile_klein.elisa",
    "mojo": "mojo/p/planar_directed_general_st_flow_borradaile_klein.mojo",
    "nim": "nim/p/planar_directed_general_st_flow_borradaile_klein.nim",
    "odin": "odin/p/planar_directed_general_st_flow_borradaile_klein.odin",
    "rust": "rust/p/planar_directed_general_st_flow_borradaile_klein.rs",
    "v": "v/p/planar_directed_general_st_flow_borradaile_klein.v",
    "zig": "zig/p/planar_directed_general_st_flow_borradaile_klein.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "isnil(input)",
    "zig": "input_ptr == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != SYMBOL:
        issues.append("inventory algorithm mismatch")
    if set(inventory.get("languages", {})) != set(PORTS):
        issues.append("inventory language set mismatch")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"input null guard missing from {relative}")
        if inventory["languages"].get(language) != relative:
            issues.append(f"inventory path mismatch for {language}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
    for url in (
        "https://doi.org/10.1145/1502793.1502798",
        "https://doi.org/10.1007/978-1-4939-2864-4_626",
        "https://doi.org/10.1137/S0097539793253565",
    ):
        if url not in readme or url not in rights:
            issues.append(f"provenance DOI missing from README or RIGHTS: {url}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()
