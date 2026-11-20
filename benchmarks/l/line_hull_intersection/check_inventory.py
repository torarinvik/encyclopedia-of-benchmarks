"""Static package inventory; this module never starts external processes."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/l/line_hull_intersection.c",
    "c3": "c3/l/line_hull_intersection.c3",
    "cpp": "cpp/l/line_hull_intersection.cpp",
    "elisa": "elisa/l/line_hull_intersection.elisa",
    "mojo": "mojo/l/line_hull_intersection.mojo",
    "nim": "nim/l/line_hull_intersection.nim",
    "odin": "odin/l/line_hull_intersection.odin",
    "rust": "rust/l/line_hull_intersection.rs",
    "v": "v/l/line_hull_intersection.v",
    "zig": "zig/l/line_hull_intersection.zig",
}
SOURCES = (
    "https://www.cs.princeton.edu/~chazelle/pubs/IntersectConvexObjects2-3Dim.pdf",
    "https://people.mpi-inf.mpg.de/~mehlhorn/ftp/EATCSmonograph/chapter8.pdf",
    "https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/chapter.tex",
    "https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/LineHullIntersection.h",
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
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif "line_hull_intersection" not in path.read_text(encoding="utf-8"):
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
