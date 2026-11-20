"""Static inventory checks for the bounded Commentz-Walter package."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/commentz_walter"
PORTS = {
    "c": ROOT / "c/c/commentz_walter.c",
    "c3": ROOT / "c3/c/commentz_walter.c3",
    "cpp": ROOT / "cpp/c/commentz_walter.cpp",
    "elisa": ROOT / "elisa/c/commentz_walter.elisa",
    "mojo": ROOT / "mojo/c/commentz_walter.mojo",
    "nim": ROOT / "nim/c/commentz_walter.nim",
    "odin": ROOT / "odin/c/commentz_walter.odin",
    "rust": ROOT / "rust/c/commentz_walter.rs",
    "v": ROOT / "v/c/commentz_walter.v",
    "zig": ROOT / "zig/c/commentz_walter.zig",
}
NULL_GUARDS = {
    "c": "values == NULL",
    "c3": "values == null",
    "cpp": "values == NULL",
    "elisa": "values.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "values.isNil",
    "odin": "values == nil",
    "rust": "values.is_null()",
    "v": "values == nil",
    "zig": "values == null",
}
SOURCES = (
    "https://xlinux.nist.gov/dads/HTML/CommentzWalter.html",
    "https://doi.org/10.1007/3-540-09510-1_10",
    "https://www.ccsl.carleton.ca/people/theses/Kelly_Master_Thesis_06.pdf",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    readme_path = PACKAGE / "README.md"
    if not readme_path.is_file():
        return ["missing README.md"]
    readme = readme_path.read_text(encoding="utf-8")
    for source in SOURCES:
        if source not in readme:
            issues.append(f"README missing source: {source}")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("https://", "http://", "#")):
            continue
        if not (PACKAGE / target).resolve().is_file():
            issues.append(f"README target missing: {target}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "commentz_walter" not in source:
            issues.append(f"symbol text missing: {path.relative_to(ROOT)}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing: {path.relative_to(ROOT)}")
        if "shift1" not in source and "shift_1" not in source:
            issues.append(f"CW shift1 table missing: {path.relative_to(ROOT)}")
        if "shift2" not in source and "shift_2" not in source:
            issues.append(f"CW shift2 table missing: {path.relative_to(ROOT)}")
        if "children" not in source and "child" not in source:
            issues.append(f"reverse-trie transitions missing: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
