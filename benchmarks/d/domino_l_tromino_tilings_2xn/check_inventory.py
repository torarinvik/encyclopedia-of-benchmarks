"""Static package inventory; no language ports are compiled or executed."""
from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/d/domino_l_tromino_tilings_2xn.c",
    "c3": "c3/d/domino_l_tromino_tilings_2xn.c3",
    "cpp": "cpp/d/domino_l_tromino_tilings_2xn.cpp",
    "elisa": "elisa/d/domino_l_tromino_tilings_2xn.elisa",
    "mojo": "mojo/d/domino_l_tromino_tilings_2xn.mojo",
    "nim": "nim/d/domino_l_tromino_tilings_2xn.nim",
    "odin": "odin/d/domino_l_tromino_tilings_2xn.odin",
    "rust": "rust/d/domino_l_tromino_tilings_2xn.rs",
    "v": "v/d/domino_l_tromino_tilings_2xn.v",
    "zig": "zig/d/domino_l_tromino_tilings_2xn.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    spec = workload.get("input", {})
    if (workload.get("algorithm") != "domino_l_tromino_tilings_2xn"
            or workload.get("function_symbol") != "domino_l_tromino_tilings_2xn"
            or workload.get("abi") != "i64_array_scalar"
            or spec.get("width_range") != [0, 32]
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
        elif "domino_l_tromino_tilings_2xn" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol: {relative}")
    issues.extend(verify_workload(workload))
    return issues
