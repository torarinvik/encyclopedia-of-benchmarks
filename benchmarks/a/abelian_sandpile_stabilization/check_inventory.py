"""Static package, language-port, and workload inventory."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/a/abelian_sandpile_stabilization.c",
    "c3": "c3/a/abelian_sandpile_stabilization.c3",
    "cpp": "cpp/a/abelian_sandpile_stabilization.cpp",
    "elisa": "elisa/a/abelian_sandpile_stabilization.elisa",
    "mojo": "mojo/a/abelian_sandpile_stabilization.mojo",
    "nim": "nim/a/abelian_sandpile_stabilization.nim",
    "odin": "odin/a/abelian_sandpile_stabilization.odin",
    "rust": "rust/a/abelian_sandpile_stabilization.rs",
    "v": "v/a/abelian_sandpile_stabilization.v",
    "zig": "zig/a/abelian_sandpile_stabilization.zig",
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
    except OSError as error:
        return issues + [f"cannot read package docs: {error}"]
    artifacts = ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py", "check_inventory.py")
    for artifact in artifacts:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "abelian_sandpile_stabilization" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa should keep raw pointer use in the ABI wrapper only")
    for source in ("https://repository.ias.ac.in/9280/1/311.pdf",
                   "https://rosettagit.org/tasks/abelian-sandpile-model/"):
        if source not in readme or source not in rights:
            issues.append(f"source link missing from README or RIGHTS: {source}")
    return issues
