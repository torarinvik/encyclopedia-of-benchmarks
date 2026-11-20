"""Static source and provenance inventory; it does not execute any port."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/p/perfect_totient_number.c",
    "c3": "c3/p/perfect_totient_number.c3",
    "cpp": "cpp/p/perfect_totient_number.cpp",
    "elisa": "elisa/p/perfect_totient_number.elisa",
    "mojo": "mojo/p/perfect_totient_number.mojo",
    "nim": "nim/p/perfect_totient_number.nim",
    "odin": "odin/p/perfect_totient_number.odin",
    "rust": "rust/p/perfect_totient_number.rs",
    "v": "v/p/perfect_totient_number.v",
    "zig": "zig/p/perfect_totient_number.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
)
SOURCES = (
    "https://cs.uwaterloo.ca/journals/JIS/VOL6/Cohen2/cohen50.pdf",
    "https://oeis.org/A082897",
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
        if "perfect_totient_number" not in path.read_text(encoding="utf-8"):
            issues.append(f"export symbol absent from {relative}")
        if relative not in readme:
            issues.append(f"README source link missing for {language}")
    for source in SOURCES:
        if source not in readme or source not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {source}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "def expected_result" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"predicate reference missing from {filename}")
    return issues
