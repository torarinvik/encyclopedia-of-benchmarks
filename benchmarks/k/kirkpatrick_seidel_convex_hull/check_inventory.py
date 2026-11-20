"""Static package inventory checker; authored but not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/k/kirkpatrick_seidel_convex_hull.c",
    "c3": "c3/k/kirkpatrick_seidel_convex_hull.c3",
    "cpp": "cpp/k/kirkpatrick_seidel_convex_hull.cpp",
    "elisa": "elisa/k/kirkpatrick_seidel_convex_hull.elisa",
    "mojo": "mojo/k/kirkpatrick_seidel_convex_hull.mojo",
    "nim": "nim/k/kirkpatrick_seidel_convex_hull.nim",
    "odin": "odin/k/kirkpatrick_seidel_convex_hull.odin",
    "rust": "rust/k/kirkpatrick_seidel_convex_hull.rs",
    "v": "v/k/kirkpatrick_seidel_convex_hull.v",
    "zig": "zig/k/kirkpatrick_seidel_convex_hull.zig",
}


def verify_static_inventory() -> list[str]:
    problems: list[str] = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_ports = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected_ports:
        problems.append("inventory port map mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        problems.append("inventory ABI mismatch")
    if inventory.get("function_symbol") != "kirkpatrick_seidel_convex_hull":
        problems.append("inventory symbol mismatch")
    if workload.get("algorithm") != "kirkpatrick_seidel_convex_hull":
        problems.append("workload algorithm mismatch")
    if workload.get("input", {}).get("maximum_valid_values") != 65:
        problems.append("maximum valid input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_values") != 66:
        problems.append("maximum parseable input bound mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 512:
        problems.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 16384:
        problems.append("workspace bound mismatch")
    if len(PORTS) != 10:
        problems.append("expected ten language ports")
    for language, relative_path in PORTS.items():
        source = ROOT / relative_path
        if not source.is_file():
            problems.append(f"missing {language} source: {relative_path}")
        elif "kirkpatrick_seidel_convex_hull" not in source.read_text():
            problems.append(f"missing exported symbol in {language}: {relative_path}")
    for required in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / required).is_file():
            problems.append(f"missing package artifact: {required}")
    return problems


if __name__ == "__main__":
    errors = verify_static_inventory()
    if errors:
        raise SystemExit("\n".join(errors))
