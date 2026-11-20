"""Static source and provenance check; it never invokes a compiler or port."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "hickerson_almost_integer"
PORTS = {
    "c": "c/h/hickerson_almost_integer.c",
    "c3": "c3/h/hickerson_almost_integer.c3",
    "cpp": "cpp/h/hickerson_almost_integer.cpp",
    "elisa": "elisa/h/hickerson_almost_integer.elisa",
    "mojo": "mojo/h/hickerson_almost_integer.mojo",
    "nim": "nim/h/hickerson_almost_integer.nim",
    "odin": "odin/h/hickerson_almost_integer.odin",
    "rust": "rust/h/hickerson_almost_integer.rs",
    "v": "v/h/hickerson_almost_integer.v",
    "zig": "zig/h/hickerson_almost_integer.zig",
}
SOURCES = (
    "https://mathworld.wolfram.com/AlmostInteger.html",
    "https://oeis.org/A034172",
    "https://www2.math.upenn.edu/~wilf/gfology2.pdf",
    "https://rosettagit.org/tasks/",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    ):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package provenance: {error}"]
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if SYMBOL not in source_path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for oracle in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_result" not in (PACKAGE / oracle).read_text(encoding="utf-8"):
            issues.append(f"expected-result reference missing from {oracle}")
    return issues
