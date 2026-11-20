"""Static source-presence inventory; intentionally not run in this task."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "l" / "lzw_compressed_shift_and_matching"
NAME = "lzw_compressed_shift_and_matching"
PORTS = {
    "c": ("l", ".c"),
    "c3": ("l", ".c3"),
    "cpp": ("l", ".cpp"),
    "elisa": ("l", ".elisa"),
    "mojo": ("l", ".mojo"),
    "nim": ("l", ".nim"),
    "odin": ("l", ".odin"),
    "rust": ("l", ".rs"),
    "v": ("l", ".v"),
    "zig": ("l", ".zig"),
}


def missing_files() -> list[Path]:
    required = [
        PACKAGE / "README.md",
        PACKAGE / "RIGHTS.md",
        PACKAGE / "workload.json",
        PACKAGE / "check_inventory.py",
        ROOT / "benchmarks" / f"{NAME}_oracle.py",
        ROOT / "benchmarks" / f"{NAME}_verifier_oracle.py",
    ]
    required.extend(
        ROOT / language / category / f"{NAME}{extension}"
        for language, (category, extension) in PORTS.items()
    )
    return [path for path in required if not path.is_file()]
