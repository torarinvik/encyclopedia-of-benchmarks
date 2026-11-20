"""Static inventory for the bounded 2D optimal-expected matching package."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ALGORITHM = "two_dimensional_optimal_expected_matching"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    package = Path(__file__).resolve().parent
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (package / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "t" / f"{ALGORITHM}.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port: {source.relative_to(ROOT)}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"missing ABI symbol in {language} port")
    return issues
