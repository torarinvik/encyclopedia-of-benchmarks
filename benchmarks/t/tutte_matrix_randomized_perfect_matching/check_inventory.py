"""Static package-artifact and native-port inventory."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
NAME = "tutte_matrix_randomized_perfect_matching"
PORTS = {
    "c": ("c", ".c"),
    "c3": ("c3", ".c3"),
    "cpp": ("cpp", ".cpp"),
    "elisa": ("elisa", ".elisa"),
    "mojo": ("mojo", ".mojo"),
    "nim": ("nim", ".nim"),
    "odin": ("odin", ".odin"),
    "rust": ("rust", ".rs"),
    "v": ("v", ".v"),
    "zig": ("zig", ".zig"),
}
PACKAGE_FILES = (
    "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py",
)
REFERENCES = (
    "benchmarks/tutte_matrix_randomized_perfect_matching_oracle.py",
    "benchmarks/tutte_matrix_randomized_perfect_matching_verifier_oracle.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for relative in PACKAGE_FILES:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file: {relative}")
    for relative in REFERENCES:
        if not (ROOT / relative).is_file():
            issues.append(f"missing reference: {relative}")
    for language, (directory, extension) in PORTS.items():
        path = ROOT / directory / "t" / f"{NAME}{extension}"
        if not path.is_file():
            issues.append(f"missing port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol not found: {language}")
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        issues.append(f"cannot read inventory: {error}")
        return issues
    if (not isinstance(inventory, dict)
            or inventory.get("algorithm") != NAME
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", {})) != set(PORTS)
            or set(inventory.get("package_files", [])) != set(PACKAGE_FILES)
            or set(inventory.get("root_references", [])) != set(REFERENCES)):
        issues.append("machine-readable inventory disagrees with package paths")
    elif any(inventory["native_paths"][language] !=
             f"{directory}/t/{NAME}{extension}"
             for language, (directory, extension) in PORTS.items()):
        issues.append("machine-readable native path differs from language port")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = check_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
    raise SystemExit(0)
