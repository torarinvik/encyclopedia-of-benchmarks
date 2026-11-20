"""Static package and port inventory check; it does not execute any port."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/e/ekg_sequence.c",
    "c3": "c3/e/ekg_sequence.c3",
    "cpp": "cpp/e/ekg_sequence.cpp",
    "elisa": "elisa/e/ekg_sequence.elisa",
    "mojo": "mojo/e/ekg_sequence.mojo",
    "nim": "nim/e/ekg_sequence.nim",
    "odin": "odin/e/ekg_sequence.odin",
    "rust": "rust/e/ekg_sequence.rs",
    "v": "v/e/ekg_sequence.v",
    "zig": "zig/e/ekg_sequence.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PROVENANCE_URLS = (
    "https://arxiv.org/abs/math/0204011",
    "https://oeis.org/A064413",
    "https://rosettagit.org/tasks/",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]

    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "ekg_sequence" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")

    for source_url in PROVENANCE_URLS:
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        if "def expected_output" not in (PACKAGE / name).read_text(encoding="utf-8"):
            issues.append(f"expected-output reference missing from {name}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa algorithm should use bounded views internally")
    return issues
