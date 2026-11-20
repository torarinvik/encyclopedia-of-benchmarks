"""Static source and provenance inventory; does not compile or execute ports."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/s/sieve_of_sundaram.c",
    "c3": "c3/s/sieve_of_sundaram.c3",
    "cpp": "cpp/s/sieve_of_sundaram.cpp",
    "elisa": "elisa/s/sieve_of_sundaram.elisa",
    "mojo": "mojo/s/sieve_of_sundaram.mojo",
    "nim": "nim/s/sieve_of_sundaram.nim",
    "odin": "odin/s/sieve_of_sundaram.odin",
    "rust": "rust/s/sieve_of_sundaram.rs",
    "v": "v/s/sieve_of_sundaram.v",
    "zig": "zig/s/sieve_of_sundaram.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
)
SOURCES = (
    "https://www.scientificbulletin.upb.ro/rev_docs_arhiva/fullb1a_720372.pdf",
    "https://www.mdpi.com/1999-4893/17/4/157",
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
        source = path.read_text(encoding="utf-8")
        if "sieve_of_sundaram" not in source:
            issues.append(f"export symbol absent from {relative}")
        if relative not in readme:
            issues.append(f"README source link missing for {language}")
    for source in SOURCES:
        if source not in readme or source not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {source}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "def prime_count" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"prime-count reference missing from {filename}")
    return issues
