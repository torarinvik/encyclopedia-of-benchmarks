"""Static source, documentation, and fixture inventory for the package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify as verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/l/left_truncatable_prime_search.c",
    "c3": "c3/l/left_truncatable_prime_search.c3",
    "cpp": "cpp/l/left_truncatable_prime_search.cpp",
    "elisa": "elisa/l/left_truncatable_prime_search.elisa",
    "mojo": "mojo/l/left_truncatable_prime_search.mojo",
    "nim": "nim/l/left_truncatable_prime_search.nim",
    "odin": "odin/l/left_truncatable_prime_search.odin",
    "rust": "rust/l/left_truncatable_prime_search.rs",
    "v": "v/l/left_truncatable_prime_search.v",
    "zig": "zig/l/left_truncatable_prime_search.zig",
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
SOURCE_URLS = (
    "https://doi.org/10.1090/S0025-5718-1977-0427213-2",
    "https://oeis.org/A103443/internal",
    "https://rosettagit.org/tasks/",
)


def static_issues() -> list[str]:
    issues = verify_workload()
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
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "left_truncatable_prime_search" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8") if (ROOT / PORTS["elisa"]).is_file() else ""
    if elisa and ("view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa):
        issues.append("Elisa should use a bounded view internally and keep raw pointers out of the source")
    for source_url in SOURCE_URLS:
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues


def verify() -> None:
    """Raise when package inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
