"""Static artifact and exported-source inventory review."""

from __future__ import annotations

from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "shortest_subarray_with_sum_at_least_k"
PORTS = (
    "c/s/shortest_subarray_with_sum_at_least_k.c",
    "c3/s/shortest_subarray_with_sum_at_least_k.c3",
    "cpp/s/shortest_subarray_with_sum_at_least_k.cpp",
    "elisa/s/shortest_subarray_with_sum_at_least_k.elisa",
    "mojo/s/shortest_subarray_with_sum_at_least_k.mojo",
    "nim/s/shortest_subarray_with_sum_at_least_k.nim",
    "odin/s/shortest_subarray_with_sum_at_least_k.odin",
    "rust/s/shortest_subarray_with_sum_at_least_k.rs",
    "v/s/shortest_subarray_with_sum_at_least_k.v",
    "zig/s/shortest_subarray_with_sum_at_least_k.zig",
)
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
)
SOURCE_URLS = (
    "https://doi.org/10.1016/j.ipl.2005.08.006",
    "https://leetcode.com/problems/shortest-subarray-with-sum-at-least-k/",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for artifact in ARTIFACTS:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for url in SOURCE_URLS:
            if url not in readme:
                issues.append(f"README omits source URL: {url}")
        for relative in PORTS:
            if relative not in readme:
                issues.append(f"README omits port path: {relative}")
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", readme):
            if "://" not in target and not (PACKAGE / target).resolve().is_file():
                issues.append(f"README target is missing: {target}")
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        for url in SOURCE_URLS:
            if url not in rights:
                issues.append(f"RIGHTS omits source URL: {url}")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {relative}")
    return issues
