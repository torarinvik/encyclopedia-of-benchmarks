"""Static ten-language source inventory checker; intentionally not run."""

from __future__ import annotations

import re
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
PORTS = {
    "C": "c/q/quantum_spectral_energy_expectation.c",
    "C3": "c3/q/quantum_spectral_energy_expectation.c3",
    "C++": "cpp/q/quantum_spectral_energy_expectation.cpp",
    "Elisa": "elisa/q/quantum_spectral_energy_expectation.elisa",
    "Mojo": "mojo/q/quantum_spectral_energy_expectation.mojo",
    "Nim": "nim/q/quantum_spectral_energy_expectation.nim",
    "Odin": "odin/q/quantum_spectral_energy_expectation.odin",
    "Rust": "rust/q/quantum_spectral_energy_expectation.rs",
    "V": "v/q/quantum_spectral_energy_expectation.v",
    "Zig": "zig/q/quantum_spectral_energy_expectation.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    rows = re.findall(
        r"^\| (C3|C\+\+|C|Elisa|Mojo|Nim|Odin|Rust|V|Zig) \| `([^`]+)` \|$",
        inventory, re.MULTILINE,
    )
    declared = {language: path for language, path in rows}
    if declared != PORTS:
        issues.append("inventory paths do not match the ten supported languages")
    for language, relative in PORTS.items():
        source = REPOSITORY / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif "quantum_spectral_energy_expectation" not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language} source: {relative}")
    for required in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / required).is_file():
            issues.append(f"missing package file: {required}")
    return issues
