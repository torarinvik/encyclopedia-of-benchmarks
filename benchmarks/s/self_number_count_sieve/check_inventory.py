"""Static source, documentation, and workload inventory for this package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/s/self_number_count_sieve.c",
    "c3": "c3/s/self_number_count_sieve.c3",
    "cpp": "cpp/s/self_number_count_sieve.cpp",
    "elisa": "elisa/s/self_number_count_sieve.elisa",
    "mojo": "mojo/s/self_number_count_sieve.mojo",
    "nim": "nim/s/self_number_count_sieve.nim",
    "odin": "odin/s/self_number_count_sieve.odin",
    "rust": "rust/s/self_number_count_sieve.rs",
    "v": "v/s/self_number_count_sieve.v",
    "zig": "zig/s/self_number_count_sieve.zig",
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
    for artifact in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                     "__init__.py", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.json").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "self_number_count_sieve" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
        if relative not in inventory:
            issues.append(f"inventory JSON path missing for {language}: {relative}")
    elisa_path = ROOT / PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in elisa or "*i64" in elisa:
            issues.append("Elisa must use a bounded view behind its exported FFI boundary")
    for source_url in (
        "https://mathworld.wolfram.com/SelfNumber.html",
        "https://www.primepuzzles.net/puzzles/puzz_373.htm",
        "https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
