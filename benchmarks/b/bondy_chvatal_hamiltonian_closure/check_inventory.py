"""Static package inventory check; authored only, not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/b/bondy_chvatal_hamiltonian_closure.c",
    "c3": "c3/b/bondy_chvatal_hamiltonian_closure.c3",
    "cpp": "cpp/b/bondy_chvatal_hamiltonian_closure.cpp",
    "elisa": "elisa/b/bondy_chvatal_hamiltonian_closure.elisa",
    "mojo": "mojo/b/bondy_chvatal_hamiltonian_closure.mojo",
    "nim": "nim/b/bondy_chvatal_hamiltonian_closure.nim",
    "odin": "odin/b/bondy_chvatal_hamiltonian_closure.odin",
    "rust": "rust/b/bondy_chvatal_hamiltonian_closure.rs",
    "v": "v/b/bondy_chvatal_hamiltonian_closure.v",
    "zig": "zig/b/bondy_chvatal_hamiltonian_closure.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected:
        errors.append("inventory port map mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI mismatch")
    if inventory.get("function_symbol") != "bondy_chvatal_hamiltonian_closure":
        errors.append("inventory symbol mismatch")
    if workload.get("algorithm") != "bondy_chvatal_hamiltonian_closure":
        errors.append("workload algorithm mismatch")
    if workload.get("input", {}).get("maximum_valid_input_length") != 58:
        errors.append("valid input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 59:
        errors.append("parseable input bound mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 80:
        errors.append("output cap mismatch")
    if workload.get("workspace", {}).get("bytes") != 1024:
        errors.append("workspace cap mismatch")
    if len(PORTS) != 10:
        errors.append("expected ten language ports")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} source: {relative}")
        elif "bondy_chvatal_hamiltonian_closure" not in source.read_text():
            errors.append(f"missing exported symbol in {language}: {relative}")
    for required in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")
    return errors
