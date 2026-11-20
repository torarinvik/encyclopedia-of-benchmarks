"""Static artifact and symbol-presence inventory; no port is executed."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = (
    ROOT / "c/r/rsk_row_insertion.c",
    ROOT / "c3/r/rsk_row_insertion.c3",
    ROOT / "cpp/r/rsk_row_insertion.cpp",
    ROOT / "elisa/r/rsk_row_insertion.elisa",
    ROOT / "mojo/r/rsk_row_insertion.mojo",
    ROOT / "nim/r/rsk_row_insertion.nim",
    ROOT / "odin/r/rsk_row_insertion.odin",
    ROOT / "rust/r/rsk_row_insertion.rs",
    ROOT / "v/r/rsk_row_insertion.v",
    ROOT / "zig/r/rsk_row_insertion.zig",
)
REQUIRED = (
    PACKAGE / "README.md",
    PACKAGE / "RIGHTS.md",
    PACKAGE / "INVENTORY.md",
    PACKAGE / "workload.json",
    PACKAGE / "primary_oracle.py",
    PACKAGE / "independent_oracle.py",
    PACKAGE / "validation.py",
    PACKAGE / "verify_workload.py",
)


def missing_artifacts():
    missing = [str(path.relative_to(ROOT)) for path in (*REQUIRED, *SOURCES) if not path.is_file()]
    for path in SOURCES:
        if path.is_file() and "rsk_row_insertion" not in path.read_text(encoding="utf-8"):
            missing.append(str(path.relative_to(ROOT)) + ": exported symbol not found")
    return missing
