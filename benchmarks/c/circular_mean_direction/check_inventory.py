"""Static source inventory for the circular mean direction package."""

from __future__ import annotations

from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "c" / f"circular_mean_direction.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port: {source}")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "atan2(sum(sin(theta_i)), sum(cos(theta_i)))" not in readme:
        issues.append("README does not pin the conventional resultant-direction formula")
    if "L1" not in readme or "RosettaGit" not in rights:
        issues.append("README/rights note omits method distinction or discovery provenance")
    for filename in ("circular_mean_direction_oracle.py",
                     "circular_mean_direction_independent_oracle.py"):
        if not (ROOT / "benchmarks" / filename).is_file():
            issues.append(f"missing reference: benchmarks/{filename}")
    return issues
