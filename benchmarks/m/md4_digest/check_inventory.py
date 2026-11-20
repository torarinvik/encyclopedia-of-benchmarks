"""Static source and metadata inventory for MD4 ports."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
EXPECTED_SOURCES = {
    "c": "c/m/md4_digest.c",
    "cpp": "cpp/m/md4_digest.cpp",
    "rust": "rust/m/md4_digest.rs",
    "elisa": "elisa/m/md4_digest.elisa",
    "c3": "c3/m/md4_digest.c3",
    "nim": "nim/m/md4_digest.nim",
    "odin": "odin/m/md4_digest.odin",
    "v": "v/m/md4_digest.v",
    "zig": "zig/m/md4_digest.zig",
    "mojo": "mojo/m/md4_digest.mojo",
}


def static_issues() -> list[str]:
    errors: list[str] = []
    for language, relative in EXPECTED_SOURCES.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing {language} source: {relative}")
        elif "md4_digest" not in path.read_text(encoding="utf-8"):
            errors.append(f"source lacks the exported md4_digest symbol: {relative}")
    package = Path(__file__).resolve().parent
    required = ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                "workload.json", "primary_oracle.py", "independent_oracle.py",
                "verify_workload.py")
    for name in required:
        if not (package / name).is_file():
            errors.append(f"missing package artifact: {name}")
    return errors


def inventory_errors() -> list[str]:
    return static_issues()
