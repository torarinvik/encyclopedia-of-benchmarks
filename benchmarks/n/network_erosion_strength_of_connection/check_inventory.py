"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/n/network_erosion_strength_of_connection"
ALGORITHM = "network_erosion_strength_of_connection"
LANGUAGE_PATHS = {
    "c": "c/n/network_erosion_strength_of_connection.c",
    "c3": "c3/n/network_erosion_strength_of_connection.c3",
    "cpp": "cpp/n/network_erosion_strength_of_connection.cpp",
    "elisa": "elisa/n/network_erosion_strength_of_connection.elisa",
    "mojo": "mojo/n/network_erosion_strength_of_connection.mojo",
    "nim": "nim/n/network_erosion_strength_of_connection.nim",
    "odin": "odin/n/network_erosion_strength_of_connection.odin",
    "rust": "rust/n/network_erosion_strength_of_connection.rs",
    "v": "v/n/network_erosion_strength_of_connection.v",
    "zig": "zig/n/network_erosion_strength_of_connection.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or symbol does not match the package")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI is not i64_array_bytes_output")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten expected ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for required in (
            "10.1007/978-1-4939-2864-4_598", "10.1103/PhysRevE.84.031929",
            "(N + 2) / 2", "lexicographically smallest", "graph_centrality",
        ):
            if required not in readme:
                issues.append(f"README is missing required source/contract text: {required}")
    return issues
