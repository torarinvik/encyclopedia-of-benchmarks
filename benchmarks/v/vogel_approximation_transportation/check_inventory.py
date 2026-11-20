"""Static source, documentation, and fixture inventory."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/v/vogel_approximation_transportation.c",
    "c3": "c3/v/vogel_approximation_transportation.c3",
    "cpp": "cpp/v/vogel_approximation_transportation.cpp",
    "elisa": "elisa/v/vogel_approximation_transportation.elisa",
    "mojo": "mojo/v/vogel_approximation_transportation.mojo",
    "nim": "nim/v/vogel_approximation_transportation.nim",
    "odin": "odin/v/vogel_approximation_transportation.odin",
    "rust": "rust/v/vogel_approximation_transportation.rs",
    "v": "v/v/vogel_approximation_transportation.v",
    "zig": "zig/v/vogel_approximation_transportation.zig",
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
    for artifact in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "vogel_approximation_transportation" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa_path = ROOT / PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in elisa or "*i64" in elisa:
            issues.append("Elisa should use a view in its implementation helper")
    sources = (
        "https://doi.org/10.1111/j.1540-5915.1970.tb00792.x",
        "https://egyankosh.ac.in/bitstream/123456789/28668/1/Unit-7.pdf",
        "https://rosettagit.org/tasks/vogels-approximation-method/",
    )
    for source in sources:
        if source not in readme or source not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source}")
    return issues
