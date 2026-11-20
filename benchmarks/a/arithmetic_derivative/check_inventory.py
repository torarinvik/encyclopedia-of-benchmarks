"""Static port, documentation, and workload inventory for this package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/a/arithmetic_derivative.c",
    "c3": "c3/a/arithmetic_derivative.c3",
    "cpp": "cpp/a/arithmetic_derivative.cpp",
    "elisa": "elisa/a/arithmetic_derivative.elisa",
    "mojo": "mojo/a/arithmetic_derivative.mojo",
    "nim": "nim/a/arithmetic_derivative.nim",
    "odin": "odin/a/arithmetic_derivative.odin",
    "rust": "rust/a/arithmetic_derivative.rs",
    "v": "v/a/arithmetic_derivative.v",
    "zig": "zig/a/arithmetic_derivative.zig",
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
    for artifact in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py",
                     "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
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
        if "arithmetic_derivative" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa should keep raw pointer use in the C-ABI wrapper only")
    source_urls = (
        "https://doi.org/10.4153/CMB-1961-013-0",
        "https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks",
    )
    for source_url in source_urls:
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
