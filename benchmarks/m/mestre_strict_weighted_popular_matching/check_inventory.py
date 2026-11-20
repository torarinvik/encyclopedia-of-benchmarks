"""Static package, documentation, and ten-port inventory."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "mestre_strict_weighted_popular_matching"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
    "independent_oracle.py", "verify_workload.py", "check_inventory.py", "INVENTORY.md",
)


def static_issues() -> list[str]:
    issues = [f"missing package file: {name}" for name in PACKAGE_FILES
              if not (PACKAGE / name).is_file()]
    for language, extension in PORTS.items():
        path = ROOT / language / "m" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing {language} port")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"{language} port lacks the exported symbol")
        if language == "elisa" and "input[0:length]" not in source:
            issues.append("Elisa should create a bounded input view at the ABI boundary")
    issues.extend(verify_workload())
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for name in PACKAGE_FILES:
            if name != "check_inventory.py" and f"]({name})" not in readme:
                issues.append(f"README omits package artifact link: {name}")
        for language, extension in PORTS.items():
            relative = f"../../../{language}/m/{SYMBOL}.{extension}"
            if f"]({relative})" not in readme:
                issues.append(f"README path mismatch for {language}")
    return issues
