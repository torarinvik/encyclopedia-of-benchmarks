"""Static package inventory; this module never starts external processes."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/p/polyhedron_volume.c",
    "c3": "c3/p/polyhedron_volume.c3",
    "cpp": "cpp/p/polyhedron_volume.cpp",
    "elisa": "elisa/p/polyhedron_volume.elisa",
    "mojo": "mojo/p/polyhedron_volume.mojo",
    "nim": "nim/p/polyhedron_volume.nim",
    "odin": "odin/p/polyhedron_volume.odin",
    "rust": "rust/p/polyhedron_volume.rs",
    "v": "v/p/polyhedron_volume.v",
    "zig": "zig/p/polyhedron_volume.zig",
}
SOURCES = (
    "https://www.cs.cmu.edu/~kmcrane/Projects/Other/QuadMeshVolume.pdf",
    "https://doi.org/10.1080/10867651.1996.10487458",
    "https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/chapter.tex",
    "https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/PolyhedronVolume.h",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
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
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif "polyhedron_volume" not in source.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_output" not in (PACKAGE / name).read_text(encoding="utf-8"):
            issues.append(f"output reference missing from {name}")
    return issues
