"""Read-only static check for package artifacts and exported language ports."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/l/lower_bound_circulation_feasibility"
SYMBOL = "lower_bound_circulation_feasibility"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
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
            issues.append(f"missing package artifact: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "l" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port")
            continue
        if SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"exported symbol is missing in {language}")
    return issues
