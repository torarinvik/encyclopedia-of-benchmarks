"""Static package and source-path inventory; no compilation or execution."""

from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "bagwell_varray_growth_index"
PORTS = {
    "c": "c/b/bagwell_varray_growth_index.c",
    "cpp": "cpp/b/bagwell_varray_growth_index.cpp",
    "rust": "rust/b/bagwell_varray_growth_index.rs",
    "elisa": "elisa/b/bagwell_varray_growth_index.elisa",
    "c3": "c3/b/bagwell_varray_growth_index.c3",
    "nim": "nim/b/bagwell_varray_growth_index.nim",
    "odin": "odin/b/bagwell_varray_growth_index.odin",
    "v": "v/b/bagwell_varray_growth_index.v",
    "zig": "zig/b/bagwell_varray_growth_index.zig",
    "mojo": "mojo/b/bagwell_varray_growth_index.mojo",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py", "__init__.py",
)
NULL_GUARDS = {
    "c": "input == NULL",
    "cpp": "input == nullptr",
    "rust": "input.is_null()",
    "elisa": "input.is_null()",
    "c3": "input == null",
    "nim": "input.isNil",
    "odin": "input == nil",
    "v": "isnil(input)",
    "zig": "input == null",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
}


def static_issues() -> list[str]:
    issues = workload_issues()
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]

    if inventory.get("algorithm") != SYMBOL:
        issues.append("inventory algorithm mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    if inventory.get("languages") != PORTS:
        issues.append("inventory language paths mismatch")
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if "previous_header" not in source or "current_header" not in source:
            issues.append(f"linked level headers missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"input null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing for {language}")

    for source in (
        "https://lampwww.epfl.ch/papers/techlists.pdf",
        "Bagwell",
        "Fig. 7",
    ):
        if source not in readme or source not in rights:
            issues.append(f"source provenance missing from README or RIGHTS: {source}")
    return issues
