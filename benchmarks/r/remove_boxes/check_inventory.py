"""Static source and documentation inventory for the remove_boxes package."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
LANGUAGE_PATHS = {
    "c": ROOT / "c/r/remove_boxes.c",
    "c3": ROOT / "c3/r/remove_boxes.c3",
    "cpp": ROOT / "cpp/r/remove_boxes.cpp",
    "elisa": ROOT / "elisa/r/remove_boxes.elisa",
    "mojo": ROOT / "mojo/r/remove_boxes.mojo",
    "nim": ROOT / "nim/r/remove_boxes.nim",
    "odin": ROOT / "odin/r/remove_boxes.odin",
    "rust": ROOT / "rust/r/remove_boxes.rs",
    "v": ROOT / "v/r/remove_boxes.v",
    "zig": ROOT / "zig/r/remove_boxes.zig",
}
PACKAGE_FILES = (
    "README.md",
    "RIGHTS.md",
    "workload.json",
    "primary_oracle.py",
    "independent_oracle.py",
    "verify_workload.py",
    "check_inventory.py",
)


def static_issues() -> list[str]:
    issues = [f"missing port: {language}" for language, path in LANGUAGE_PATHS.items()
              if not path.is_file()]
    package = Path(__file__).resolve().parent
    issues.extend(f"missing package file: {name}" for name in PACKAGE_FILES
                  if not (package / name).is_file())
    issues.extend(verify_workload())
    for language, path in LANGUAGE_PATHS.items():
        if path.is_file() and "remove_boxes" not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port is missing the exported symbol")
    return issues
