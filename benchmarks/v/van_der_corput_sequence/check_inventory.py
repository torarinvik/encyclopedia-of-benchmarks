"""Static inventory of package artifacts and language exports.

This checker intentionally inspects source text and documentation only. It does
not import or execute the references, workload verifier, or benchmark ports.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/v/van_der_corput_sequence.c",
    "c3": "c3/v/van_der_corput_sequence.c3",
    "cpp": "cpp/v/van_der_corput_sequence.cpp",
    "elisa": "elisa/v/van_der_corput_sequence.elisa",
    "mojo": "mojo/v/van_der_corput_sequence.mojo",
    "nim": "nim/v/van_der_corput_sequence.nim",
    "odin": "odin/v/van_der_corput_sequence.odin",
    "rust": "rust/v/van_der_corput_sequence.rs",
    "v": "v/v/van_der_corput_sequence.v",
    "zig": "zig/v/van_der_corput_sequence.zig",
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
    "README.md",
    "RIGHTS.md",
    "INVENTORY.md",
    "workload.json",
    "primary_oracle.py",
    "independent_oracle.py",
    "verify_workload.py",
    "check_inventory.py",
)
PROVENANCE_URLS = (
    "https://people.math.sc.edu/Burkardt/f_src/van_der_corput/van_der_corput.html",
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
        if "van_der_corput_sequence" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")

    for source_url in PROVENANCE_URLS:
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")

    for name in ("primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        source = (PACKAGE / name).read_text(encoding="utf-8")
        if "expected_output" not in source and name != "verify_workload.py":
            issues.append(f"expected-output reference missing from {name}")
    checker = (PACKAGE / "check_inventory.py").read_text(encoding="utf-8")
    if "from .verify_workload import" in checker or "subprocess" in checker:
        issues.append("inventory checker must remain a static source/documentation audit")
    return issues
