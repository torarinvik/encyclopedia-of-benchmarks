"""Static source and provenance inventory; it does not execute language ports."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/t/thiele_rational_interpolation.c",
    "c3": "c3/t/thiele_rational_interpolation.c3",
    "cpp": "cpp/t/thiele_rational_interpolation.cpp",
    "elisa": "elisa/t/thiele_rational_interpolation.elisa",
    "mojo": "mojo/t/thiele_rational_interpolation.mojo",
    "nim": "nim/t/thiele_rational_interpolation.nim",
    "odin": "odin/t/thiele_rational_interpolation.odin",
    "rust": "rust/t/thiele_rational_interpolation.rs",
    "v": "v/t/thiele_rational_interpolation.v",
    "zig": "zig/t/thiele_rational_interpolation.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
)
SOURCES = (
    "https://www.math.kent.edu/~reichel/courses/numerical.analysis.2/Numerical-book.pdf",
    "https://doi.org/10.1007/BF02144105",
    "https://rosettagit.org/tasks/",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package notes: {error}"]
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        if "thiele_rational_interpolation" not in path.read_text(encoding="utf-8"):
            issues.append(f"export symbol absent from {relative}")
        if relative not in readme:
            issues.append(f"README source link missing for {language}")
    for source in SOURCES:
        if source not in readme or source not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {source}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "def expected_output" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"interpolant reference missing from {filename}")
    return issues
