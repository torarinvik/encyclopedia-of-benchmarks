"""Static port, documentation, and workload inventory for U(1,2)."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/u/ulam_sequence_1_2.c",
    "cpp": "cpp/u/ulam_sequence_1_2.cpp",
    "rust": "rust/u/ulam_sequence_1_2.rs",
    "elisa": "elisa/u/ulam_sequence_1_2.elisa",
    "c3": "c3/u/ulam_sequence_1_2.c3",
    "nim": "nim/u/ulam_sequence_1_2.nim",
    "odin": "odin/u/ulam_sequence_1_2.odin",
    "v": "v/u/ulam_sequence_1_2.v",
    "zig": "zig/u/ulam_sequence_1_2.zig",
    "mojo": "mojo/u/ulam_sequence_1_2.mojo",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "cpp": "input == nullptr",
    "rust": "input.is_null()",
    "elisa": "input.is_null()",
    "c3": "input == null",
    "nim": "input.isNil",
    "odin": "input == nil",
    "v": "input == nil",
    "zig": "input == null",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
}


def static_issues() -> list[str]:
    issues = verify()
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                 "workload.json", "primary_oracle.py", "independent_oracle.py",
                 "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "ulam_sequence_1_2" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa should keep the FFI pointer at the exported boundary")
    for source_url in (
        "https://mathworld.wolfram.com/UlamSequence.html",
        "https://oeis.org/A002858",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
