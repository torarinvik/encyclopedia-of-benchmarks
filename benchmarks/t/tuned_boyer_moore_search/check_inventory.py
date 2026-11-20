"""Static source inventory and provenance audit; ports are not executed."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/t/tuned_boyer_moore_search.c",
    "c3": "c3/t/tuned_boyer_moore_search.c3",
    "cpp": "cpp/t/tuned_boyer_moore_search.cpp",
    "elisa": "elisa/t/tuned_boyer_moore_search.elisa",
    "mojo": "mojo/t/tuned_boyer_moore_search.mojo",
    "nim": "nim/t/tuned_boyer_moore_search.nim",
    "odin": "odin/t/tuned_boyer_moore_search.odin",
    "rust": "rust/t/tuned_boyer_moore_search.rs",
    "v": "v/t/tuned_boyer_moore_search.v",
    "zig": "zig/t/tuned_boyer_moore_search.zig",
}
INPUT_GUARDS = {
    "c": "input == NULL", "c3": "input == null", "cpp": "input == nullptr",
    "elisa": "input.is_null()", "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil", "odin": "input == nil", "rust": "input.is_null()",
    "v": "input == nil", "zig": "input == null",
}
OUTPUT_GUARDS = {
    "c": "output == NULL", "c3": "output == null", "cpp": "output == nullptr",
    "elisa": "output.is_null()", "mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
    "nim": "output.isNil", "odin": "output == nil", "rust": "output.is_null()",
    "v": "output == nil", "zig": "output == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PROVENANCE_URLS = (
    "https://doi.org/10.1002/spe.4380211105",
    "https://igm.univ-mlv.fr/~lecroq/string/tunedbm.html",
    "https://igm.univ-mlv.fr/~lecroq/string/node14.html",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for filename in REQUIRED:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "tuned_boyer_moore_search" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if INPUT_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if OUTPUT_GUARDS[language] not in source:
            issues.append(f"null-output guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    for url in PROVENANCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {url}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "def expected_output" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"expected-output reference missing from {filename}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa algorithm should use bounded views internally")
    return issues
