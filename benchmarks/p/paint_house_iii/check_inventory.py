"""Static package-artifact and exported-port inventory review."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "paint_house_iii"
PORTS = (
    "c/p/paint_house_iii.c",
    "c3/p/paint_house_iii.c3",
    "cpp/p/paint_house_iii.cpp",
    "elisa/p/paint_house_iii.elisa",
    "mojo/p/paint_house_iii.mojo",
    "nim/p/paint_house_iii.nim",
    "odin/p/paint_house_iii.odin",
    "rust/p/paint_house_iii.rs",
    "v/p/paint_house_iii.v",
    "zig/p/paint_house_iii.zig",
)
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
SOURCE_URL = "https://leetcode.com/problems/paint-house-iii/"


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in ARTIFACTS:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for path, label in ((PACKAGE / "README.md", "README"), (PACKAGE / "RIGHTS.md", "RIGHTS")):
        if path.is_file() and SOURCE_URL not in path.read_text(encoding="utf-8"):
            issues.append(f"{label} omits official source URL")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for relative in PORTS:
            if relative not in readme:
                issues.append(f"README omits port path: {relative}")
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", readme):
            if "://" not in target and not (PACKAGE / target).resolve().is_file():
                issues.append(f"README target is missing: {target}")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {relative}")
    return issues
