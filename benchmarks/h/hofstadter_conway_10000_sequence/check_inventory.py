"""Static inventory checks; never compiles or executes language ports."""
from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/h/hofstadter_conway_10000_sequence.c",
    "c3": "c3/h/hofstadter_conway_10000_sequence.c3",
    "cpp": "cpp/h/hofstadter_conway_10000_sequence.cpp",
    "elisa": "elisa/h/hofstadter_conway_10000_sequence.elisa",
    "mojo": "mojo/h/hofstadter_conway_10000_sequence.mojo",
    "nim": "nim/h/hofstadter_conway_10000_sequence.nim",
    "odin": "odin/h/hofstadter_conway_10000_sequence.odin",
    "rust": "rust/h/hofstadter_conway_10000_sequence.rs",
    "v": "v/h/hofstadter_conway_10000_sequence.v",
    "zig": "zig/h/hofstadter_conway_10000_sequence.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    spec = workload.get("input", {})
    if (workload.get("algorithm") != "hofstadter_conway_10000_sequence"
            or workload.get("function_symbol") != "hofstadter_conway_10000_sequence"
            or workload.get("abi") != "i64_array_scalar"
            or spec.get("index_range") != [2, 8192]
            or spec.get("maximum_valid_length") != 1
            or spec.get("maximum_parseable_length") != 2
            or workload.get("workspace", {}).get("bytes") != 65544):
        issues.append("workload metadata or bounds differ from the package contract")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
                     "check_inventory.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    for relative in PORTS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language source: {relative}")
        elif "hofstadter_conway_10000_sequence" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol: {relative}")
    if (PACKAGE / "INVENTORY.md").is_file():
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
        for relative in PORTS.values():
            if relative not in inventory:
                issues.append(f"inventory does not list source: {relative}")
    issues.extend(verify_workload(workload))
    return issues
