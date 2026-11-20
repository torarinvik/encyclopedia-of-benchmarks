"""Static source and metadata inventory helper; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_LANGUAGES = {
    "c": "c/m/modified_newton_multiple_root.c",
    "c3": "c3/m/modified_newton_multiple_root.c3",
    "cpp": "cpp/m/modified_newton_multiple_root.cpp",
    "elisa": "elisa/m/modified_newton_multiple_root.elisa",
    "mojo": "mojo/m/modified_newton_multiple_root.mojo",
    "nim": "nim/m/modified_newton_multiple_root.nim",
    "odin": "odin/m/modified_newton_multiple_root.odin",
    "rust": "rust/m/modified_newton_multiple_root.rs",
    "v": "v/m/modified_newton_multiple_root.v",
    "zig": "zig/m/modified_newton_multiple_root.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ["inventory or workload is unreadable or invalid JSON"]
    if inventory.get("algorithm") != "modified_newton_multiple_root":
        issues.append("inventory algorithm differs from package name")
    if inventory.get("abi") != "float64_pair":
        issues.append("inventory ABI differs from package")
    if inventory.get("languages") != EXPECTED_LANGUAGES:
        issues.append("inventory does not list exactly the ten expected source paths")
    for relative in EXPECTED_LANGUAGES.values():
        if not (ROOT / relative).is_file():
            issues.append(f"missing language source: {relative}")
    expected_package_paths = {
        "workload": "benchmarks/m/modified_newton_multiple_root/workload.json",
        "primary_oracle": "benchmarks/m/modified_newton_multiple_root/primary_oracle.py",
        "independent_oracle": "benchmarks/m/modified_newton_multiple_root/independent_oracle.py",
    }
    for key, relative in expected_package_paths.items():
        if inventory.get(key) != relative:
            issues.append(f"inventory {key} path differs from package")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload algorithm differs from inventory")
    if not workload.get("cases"):
        issues.append("workload has no fixtures")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
