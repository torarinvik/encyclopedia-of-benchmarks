"""Static package-artifact and exported-port inventory review."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "number_of_ways_of_cutting_a_pizza"
PORTS = (
    "c/n/number_of_ways_of_cutting_a_pizza.c",
    "c3/n/number_of_ways_of_cutting_a_pizza.c3",
    "cpp/n/number_of_ways_of_cutting_a_pizza.cpp",
    "elisa/n/number_of_ways_of_cutting_a_pizza.elisa",
    "mojo/n/number_of_ways_of_cutting_a_pizza.mojo",
    "nim/n/number_of_ways_of_cutting_a_pizza.nim",
    "odin/n/number_of_ways_of_cutting_a_pizza.odin",
    "rust/n/number_of_ways_of_cutting_a_pizza.rs",
    "v/n/number_of_ways_of_cutting_a_pizza.v",
    "zig/n/number_of_ways_of_cutting_a_pizza.zig",
)
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
SOURCE_URL = "https://leetcode.com/problems/number-of-ways-of-cutting-a-pizza/"


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in ARTIFACTS:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    for path, label in ((readme_path, "README"), (rights_path, "RIGHTS")):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        if SOURCE_URL not in text:
            issues.append(f"{label} omits official source URL")
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
