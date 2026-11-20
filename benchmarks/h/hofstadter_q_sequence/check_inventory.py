"""Static inventory checks; never compiles or executes language ports."""
from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/h/hofstadter_q_sequence.c",
    "c3": "c3/h/hofstadter_q_sequence.c3",
    "cpp": "cpp/h/hofstadter_q_sequence.cpp",
    "elisa": "elisa/h/hofstadter_q_sequence.elisa",
    "mojo": "mojo/h/hofstadter_q_sequence.mojo",
    "nim": "nim/h/hofstadter_q_sequence.nim",
    "odin": "odin/h/hofstadter_q_sequence.odin",
    "rust": "rust/h/hofstadter_q_sequence.rs",
    "v": "v/h/hofstadter_q_sequence.v",
    "zig": "zig/h/hofstadter_q_sequence.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    spec = workload.get("input", {})
    if (workload.get("algorithm") != "hofstadter_q_sequence"
            or workload.get("function_symbol") != "hofstadter_q_sequence"
            or workload.get("abi") != "i64_array_scalar"
            or spec.get("index_range") != [1, 128]
            or spec.get("maximum_valid_length") != 1
            or spec.get("maximum_parseable_length") != 2):
        issues.append("workload metadata or bounds differ from the package contract")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    for relative in PORTS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language source: {relative}")
        elif "hofstadter_q_sequence" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol: {relative}")
    for oracle in ("primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / oracle).is_file():
            issues.append(f"missing reference: {oracle}")
    issues.extend(verify_workload(workload))
    return issues
