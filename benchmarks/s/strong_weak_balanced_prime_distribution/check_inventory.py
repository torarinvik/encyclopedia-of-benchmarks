"""Static source, documentation, and fixture inventory for this package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify as verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/s/strong_weak_balanced_prime_distribution.c",
    "c3": "c3/s/strong_weak_balanced_prime_distribution.c3",
    "cpp": "cpp/s/strong_weak_balanced_prime_distribution.cpp",
    "elisa": "elisa/s/strong_weak_balanced_prime_distribution.elisa",
    "mojo": "mojo/s/strong_weak_balanced_prime_distribution.mojo",
    "nim": "nim/s/strong_weak_balanced_prime_distribution.nim",
    "odin": "odin/s/strong_weak_balanced_prime_distribution.odin",
    "rust": "rust/s/strong_weak_balanced_prime_distribution.rs",
    "v": "v/s/strong_weak_balanced_prime_distribution.v",
    "zig": "zig/s/strong_weak_balanced_prime_distribution.zig",
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
    "https://rosettagit.org/tasks/",
    "https://oeis.org/A051634",
    "https://oeis.org/A051635",
    "https://oeis.org/A006562",
    "https://oeis.org/A006880",
    "https://oeis.org/A159687",
    "https://oeis.org/A055206",
    "https://cp-algorithms.com/algebra/sieve-of-eratosthenes.html",
    "https://mathworld.wolfram.com/BertrandsPostulate.html",
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
        if "strong_weak_balanced_prime_distribution" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa_path = ROOT / PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa:
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
