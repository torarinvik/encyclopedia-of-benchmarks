"""Static source inventory and provenance audit; no ports are executed."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/t/turbo_boyer_moore_search.c",
    "c3": "c3/t/turbo_boyer_moore_search.c3",
    "cpp": "cpp/t/turbo_boyer_moore_search.cpp",
    "elisa": "elisa/t/turbo_boyer_moore_search.elisa",
    "mojo": "mojo/t/turbo_boyer_moore_search.mojo",
    "nim": "nim/t/turbo_boyer_moore_search.nim",
    "odin": "odin/t/turbo_boyer_moore_search.odin",
    "rust": "rust/t/turbo_boyer_moore_search.rs",
    "v": "v/t/turbo_boyer_moore_search.v",
    "zig": "zig/t/turbo_boyer_moore_search.zig",
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
OUTPUT_GUARDS = {
    "c": "output == NULL",
    "c3": "output == null",
    "cpp": "output == nullptr",
    "elisa": "output.is_null()",
    "mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
    "nim": "output.isNil",
    "odin": "output == nil",
    "rust": "output.is_null()",
    "v": "output == nil",
    "zig": "output == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PROVENANCE_URLS = (
    "https://doi.org/10.1007/BF01185427",
    "https://igm.univ-mlv.fr/~lecroq/string/node15.html",
    "https://igm.univ-mlv.fr/~lecroq/string/node14.html",
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
        if "turbo_boyer_moore_search" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if OUTPUT_GUARDS[language] not in source:
            issues.append(f"null-output guard missing from {relative}")
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
