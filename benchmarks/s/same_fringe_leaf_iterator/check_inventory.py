"""Static source, documentation, and workload inventory for this package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/s/same_fringe_leaf_iterator.c",
    "c3": "c3/s/same_fringe_leaf_iterator.c3",
    "cpp": "cpp/s/same_fringe_leaf_iterator.cpp",
    "elisa": "elisa/s/same_fringe_leaf_iterator.elisa",
    "mojo": "mojo/s/same_fringe_leaf_iterator.mojo",
    "nim": "nim/s/same_fringe_leaf_iterator.nim",
    "odin": "odin/s/same_fringe_leaf_iterator.odin",
    "rust": "rust/s/same_fringe_leaf_iterator.rs",
    "v": "v/s/same_fringe_leaf_iterator.v",
    "zig": "zig/s/same_fringe_leaf_iterator.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}


def static_issues() -> list[str]:
    issues = verify()
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.json").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package metadata: {error}"]
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                 "__init__.py", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "same_fringe_leaf_iterator" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
        if relative not in inventory:
            issues.append(f"inventory JSON path missing for {language}: {relative}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa must keep the raw FFI boundary thin and use views internally")
    for source_url in (
        "https://doi.org/10.1016/j.scico.2006.01.002",
        "https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
