"""Static artifact-presence checker for the KACTL constant-interval package."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "C": ROOT / "c/c/constant_intervals.c",
    "C3": ROOT / "c3/c/constant_intervals.c3",
    "C++": ROOT / "cpp/c/constant_intervals.cpp",
    "Elisa": ROOT / "elisa/c/constant_intervals.elisa",
    "Mojo": ROOT / "mojo/c/constant_intervals.mojo",
    "Nim": ROOT / "nim/c/constant_intervals.nim",
    "Odin": ROOT / "odin/c/constant_intervals.odin",
    "Rust": ROOT / "rust/c/constant_intervals.rs",
    "V": ROOT / "v/c/constant_intervals.v",
    "Zig": ROOT / "zig/c/constant_intervals.zig",
}
REQUIRED = (
    PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "INVENTORY.md",
    PACKAGE / "workload.json", PACKAGE / "primary_oracle.py",
    PACKAGE / "independent_oracle.py",
)


def missing_artifacts() -> list[str]:
    missing = [str(path.relative_to(ROOT)) for path in REQUIRED if not path.is_file()]
    missing.extend(str(path.relative_to(ROOT)) for path in SOURCES.values() if not path.is_file())
    return missing
