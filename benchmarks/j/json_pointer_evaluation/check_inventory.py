"""Static artifact and native-port inventory; intentionally not run."""

from __future__ import annotations

from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_SOURCES = {
    "c": ROOT / "c/j/json_pointer_evaluation.c",
    "c3": ROOT / "c3/j/json_pointer_evaluation.c3",
    "cpp": ROOT / "cpp/j/json_pointer_evaluation.cpp",
    "elisa": ROOT / "elisa/j/json_pointer_evaluation.elisa",
    "mojo": ROOT / "mojo/j/json_pointer_evaluation.mojo",
    "nim": ROOT / "nim/j/json_pointer_evaluation.nim",
    "odin": ROOT / "odin/j/json_pointer_evaluation.odin",
    "rust": ROOT / "rust/j/json_pointer_evaluation.rs",
    "v": ROOT / "v/j/json_pointer_evaluation.v",
    "zig": ROOT / "zig/j/json_pointer_evaluation.zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, source in LANGUAGE_SOURCES.items():
        if not source.is_file():
            issues.append(f"missing {language} port: {source.relative_to(ROOT)}")
        elif "json_pointer_evaluation" not in source.read_text(encoding="utf-8"):
            issues.append(f"missing export symbol in {language} port")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("inventory issues: " + "; ".join(problems))
