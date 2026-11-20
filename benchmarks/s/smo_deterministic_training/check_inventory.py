"""Static package completeness checks; this module is not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
BENCHMARKS = ROOT / "benchmarks"
NAME = "smo_deterministic_training"
PORTS = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "mojo": "mojo",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}


def static_issues() -> tuple[str, ...]:
    issues: list[str] = []
    for language, extension in PORTS.items():
        path = ROOT / language / "s" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing {language} source: {path}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "SOURCE_CROSSWALK.md",
                 "workload.json", "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for name in ("smo_deterministic_training_oracle.py", "smo_deterministic_training_verifier_oracle.py"):
        if not (BENCHMARKS / name).is_file():
            issues.append(f"missing reference: {name}")
    if issues:
        return tuple(issues)
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "float64_slice_io"
            or workload.get("input", {}).get("maximum_valid_input_length") != 36
            or workload.get("input", {}).get("maximum_parseable_input_length") != 37
            or workload.get("output", {}).get("maximum_elements") != 12
            or workload.get("output", {}).get("maximum_bytes") != 96
            or workload.get("workspace", {}).get("bytes") != 4096
            or workload.get("contract", {}).get("bias_convention") !=
                "the input-independent decision intercept is the negative of Platt's subtractive threshold b"):
        issues.append("workload metadata differs from the bounded ABI contract")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    if "Chapter 415" not in readme or "§§2.1–2.5" not in readme:
        issues.append("README does not pin the chapter sections")
    if "No redistribution license is claimed" not in rights:
        issues.append("rights note must state the redistribution status")
    if any(name not in inventory for name in PORTS):
        issues.append("inventory does not list every language port")
    return tuple(issues)
