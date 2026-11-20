"""Static package files, exports, links, and provenance inventory."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/p/polygon_area_centroid.c",
    "c3": "c3/p/polygon_area_centroid.c3",
    "cpp": "cpp/p/polygon_area_centroid.cpp",
    "elisa": "elisa/p/polygon_area_centroid.elisa",
    "mojo": "mojo/p/polygon_area_centroid.mojo",
    "nim": "nim/p/polygon_area_centroid.nim",
    "odin": "odin/p/polygon_area_centroid.odin",
    "rust": "rust/p/polygon_area_centroid.rs",
    "v": "v/p/polygon_area_centroid.v",
    "zig": "zig/p/polygon_area_centroid.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
SOURCES = (
    "https://doi.org/10.1061/(ASCE)0887-3801(1995)9:1(88)",
    "https://faculty.washington.edu/greulich/Documents/Centroid.pdf",
    "https://tomkom.pages.gitlab.unimelb.edu.au/spatialdatamanagement/21_geometrical_analysis.html",
    "https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/chapter.tex",
    "https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/PolygonCenter.h",
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
        if "polygon_area_centroid" not in source:
            issues.append(f"exported symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")

    for reference in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_output" not in (PACKAGE / reference).read_text(encoding="utf-8"):
            issues.append(f"expected-output reference missing from {reference}")
    checker = (PACKAGE / "check_inventory.py").read_text(encoding="utf-8")
    if "subprocess" in checker:
        issues.append("inventory checker must remain static and must not invoke programs")
    return issues
