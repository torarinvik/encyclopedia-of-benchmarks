"""Static source, documentation, and workload inventory."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/m/misra_gries_edge_coloring.c",
    "c3": "c3/m/misra_gries_edge_coloring.c3",
    "cpp": "cpp/m/misra_gries_edge_coloring.cpp",
    "elisa": "elisa/m/misra_gries_edge_coloring.elisa",
    "mojo": "mojo/m/misra_gries_edge_coloring.mojo",
    "nim": "nim/m/misra_gries_edge_coloring.nim",
    "odin": "odin/m/misra_gries_edge_coloring.odin",
    "rust": "rust/m/misra_gries_edge_coloring.rs",
    "v": "v/m/misra_gries_edge_coloring.v",
    "zig": "zig/m/misra_gries_edge_coloring.zig",
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
        return issues + [f"cannot read package docs: {error}"]
    required = ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                "independent_oracle.py", "verify_workload.py", "check_inventory.py")
    for artifact in required:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "misra_gries_edge_coloring" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    for source in (
        "https://doi.org/10.1016/0020-0190(92)90041-S",
        "https://www.cs.utexas.edu/~misra/psp.dir/vizing.pdf",
        "https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/EdgeColoring.h",
    ):
        if source not in readme or source not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source}")
    return issues
