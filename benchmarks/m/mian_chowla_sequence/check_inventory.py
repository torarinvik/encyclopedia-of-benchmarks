"""Static port, documentation, and workload inventory for this package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/m/mian_chowla_sequence.c",
    "c3": "c3/m/mian_chowla_sequence.c3",
    "cpp": "cpp/m/mian_chowla_sequence.cpp",
    "elisa": "elisa/m/mian_chowla_sequence.elisa",
    "mojo": "mojo/m/mian_chowla_sequence.mojo",
    "nim": "nim/m/mian_chowla_sequence.nim",
    "odin": "odin/m/mian_chowla_sequence.odin",
    "rust": "rust/m/mian_chowla_sequence.rs",
    "v": "v/m/mian_chowla_sequence.v",
    "zig": "zig/m/mian_chowla_sequence.zig",
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
        return issues + [f"cannot read package documentation: {error}"]
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "mian_chowla_sequence" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa should keep raw pointer use in the C-ABI wrapper only")
    source_urls = (
        "https://oeis.org/A005282",
        "https://rosettagit.org/tasks/mian-chowla-sequence/",
        "https://journals.us.edu.pl/index.php/AMSIL/article/download/14110/10834/40240",
    )
    for source_url in source_urls:
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
