"""Static inventory checks for the Ring-Expander package; not run in this draft."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPO = PACKAGE.parents[2]
NAME = "ring_expander_closed_triangle_mesh"
PORTS = {
    "c": "c/r/ring_expander_closed_triangle_mesh.c",
    "c3": "c3/r/ring_expander_closed_triangle_mesh.c3",
    "cpp": "cpp/r/ring_expander_closed_triangle_mesh.cpp",
    "elisa": "elisa/r/ring_expander_closed_triangle_mesh.elisa",
    "mojo": "mojo/r/ring_expander_closed_triangle_mesh.mojo",
    "nim": "nim/r/ring_expander_closed_triangle_mesh.nim",
    "odin": "odin/r/ring_expander_closed_triangle_mesh.odin",
    "rust": "rust/r/ring_expander_closed_triangle_mesh.rs",
    "v": "v/r/ring_expander_closed_triangle_mesh.v",
    "zig": "zig/r/ring_expander_closed_triangle_mesh.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for relative in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "check_inventory.py", "verify_workload.py",
        "../../ring_expander_closed_triangle_mesh_oracle.py",
        "../../ring_expander_closed_triangle_mesh_verifier_oracle.py",
    ):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    for relative in PORTS.values():
        if not (REPO / relative).is_file():
            issues.append(f"missing language port: {relative}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        issues.append(f"cannot read package metadata: {error}")
        return issues
    if inventory.get("algorithm") != NAME or inventory.get("symbol") != NAME:
        issues.append("inventory algorithm/symbol mismatch")
    if inventory.get("ports") != PORTS:
        issues.append("inventory port map mismatch")
    if inventory.get("source_level_peak_accounted_bytes") != 5816:
        issues.append("inventory source-level workspace account mismatch")
    if inventory.get("complexity", {}).get("edge_incidence_and_opposite_setup") != "O(t+v^2)":
        issues.append("inventory edge-setup complexity mismatch")
    if workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME:
        issues.append("workload algorithm/symbol mismatch")
    if workload.get("input", {}).get("maximum_valid_input_length") != 63:
        issues.append("valid-input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 64:
        issues.append("parseable-input bound mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 504:
        issues.append("output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 8192:
        issues.append("workspace bound mismatch")
    if workload.get("workspace", {}).get("source_level_peak_accounted_bytes") != 5816:
        issues.append("source-level workspace account mismatch")
    if workload.get("contract", {}).get("complexity") != (
        "Native ports: edge-incidence/opposite-corner setup O(t+v^2), dense vertex-link validation O(v^3), and Ring-Expander walk O(t). The independent oracle scans all face edges for each opposite-corner lookup, O(t^2)."
    ):
        issues.append("complexity contract mismatch")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing alias for package inventory validation."""
    return static_issues()


if __name__ == "__main__":
    problems = check_inventory()
    if problems:
        for problem in problems:
            print(problem)
        raise SystemExit(1)
    print("Ring-Expander package inventory is complete")
