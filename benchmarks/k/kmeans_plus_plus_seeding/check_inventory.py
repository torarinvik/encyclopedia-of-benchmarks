"""Static source, artifact, export, and provenance inventory.

This checker reads files and source text only. It does not import or execute the
references, workload verifier, or benchmark ports.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/k/kmeans_plus_plus_seeding.c",
    "c3": "c3/k/kmeans_plus_plus_seeding.c3",
    "cpp": "cpp/k/kmeans_plus_plus_seeding.cpp",
    "elisa": "elisa/k/kmeans_plus_plus_seeding.elisa",
    "mojo": "mojo/k/kmeans_plus_plus_seeding.mojo",
    "nim": "nim/k/kmeans_plus_plus_seeding.nim",
    "odin": "odin/k/kmeans_plus_plus_seeding.odin",
    "rust": "rust/k/kmeans_plus_plus_seeding.rs",
    "v": "v/k/kmeans_plus_plus_seeding.v",
    "zig": "zig/k/kmeans_plus_plus_seeding.zig",
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
    "https://theory.stanford.edu/~sergei/papers/kMeansPP-soda.pdf",
    "https://research.google/pubs/k-means-the-advantages-of-careful-seeding/",
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
        if "kmeans_plus_plus_seeding" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")

    for source_url in PROVENANCE_URLS:
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")

    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa should keep pointer handling at the C ABI wrapper and use bounded views internally")

    for name in ("primary_oracle.py", "independent_oracle.py"):
        source = (PACKAGE / name).read_text(encoding="utf-8")
        if "expected_output" not in source:
            issues.append(f"expected-output reference missing from {name}")
    checker = (PACKAGE / "check_inventory.py").read_text(encoding="utf-8")
    if "from .verify_workload import" in checker or "subprocess" in checker:
        issues.append("inventory checker must remain a static source/documentation audit")
    return issues
