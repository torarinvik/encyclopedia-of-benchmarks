"""Static inventory for the HsaDelta differential-compression package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
LANGUAGE_PATHS = {
    "c": ROOT / "c/h/hsadelta_differential_compression.c",
    "c3": ROOT / "c3/h/hsadelta_differential_compression.c3",
    "cpp": ROOT / "cpp/h/hsadelta_differential_compression.cpp",
    "elisa": ROOT / "elisa/h/hsadelta_differential_compression.elisa",
    "mojo": ROOT / "mojo/h/hsadelta_differential_compression.mojo",
    "nim": ROOT / "nim/h/hsadelta_differential_compression.nim",
    "odin": ROOT / "odin/h/hsadelta_differential_compression.odin",
    "rust": ROOT / "rust/h/hsadelta_differential_compression.rs",
    "v": ROOT / "v/h/hsadelta_differential_compression.v",
    "zig": ROOT / "zig/h/hsadelta_differential_compression.zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
    "independent_oracle.py", "verify_workload.py", "check_inventory.py",
    "INVENTORY.md",
)


def static_issues() -> list[str]:
    issues = [f"missing port: {language}" for language, path in LANGUAGE_PATHS.items()
              if not path.is_file()]
    package = Path(__file__).resolve().parent
    issues.extend(f"missing package file: {name}" for name in PACKAGE_FILES
                  if not (package / name).is_file())
    issues.extend(verify_workload())
    for language, path in LANGUAGE_PATHS.items():
        if path.is_file() and "hsadelta_differential_compression" not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port is missing the exported symbol")
    return issues
