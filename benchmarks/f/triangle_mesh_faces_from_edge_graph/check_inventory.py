"""Static package/path check; this helper is authored, not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/f/triangle_mesh_faces_from_edge_graph.c",
    "c3": "c3/f/triangle_mesh_faces_from_edge_graph.c3",
    "cpp": "cpp/f/triangle_mesh_faces_from_edge_graph.cpp",
    "elisa": "elisa/f/triangle_mesh_faces_from_edge_graph.elisa",
    "mojo": "mojo/f/triangle_mesh_faces_from_edge_graph.mojo",
    "nim": "nim/f/triangle_mesh_faces_from_edge_graph.nim",
    "odin": "odin/f/triangle_mesh_faces_from_edge_graph.odin",
    "rust": "rust/f/triangle_mesh_faces_from_edge_graph.rs",
    "v": "v/f/triangle_mesh_faces_from_edge_graph.v",
    "zig": "zig/f/triangle_mesh_faces_from_edge_graph.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_paths = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected_paths:
        errors.append("inventory port map mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI mismatch")
    if inventory.get("function_symbol") != "triangle_mesh_faces_from_edge_graph":
        errors.append("inventory symbol mismatch")
    if workload.get("algorithm") != "triangle_mesh_faces_from_edge_graph":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_valid_input_length") != 58:
        errors.append("valid input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 59:
        errors.append("parseable input bound mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 1360:
        errors.append("output cap mismatch")
    if workload.get("workspace", {}).get("bytes") != 8192:
        errors.append("workspace cap mismatch")
    if len(PORTS) != 10:
        errors.append("expected ten language ports")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} source: {relative}")
        elif "triangle_mesh_faces_from_edge_graph" not in source.read_text():
            errors.append(f"missing exported symbol in {language}: {relative}")
    for required in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")
    return errors


if __name__ == "__main__":
    problems = verify_static_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
