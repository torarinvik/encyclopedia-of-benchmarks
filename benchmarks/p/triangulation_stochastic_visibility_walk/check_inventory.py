"""Static package inventory checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/p/triangulation_stochastic_visibility_walk"
ALGORITHM = "triangulation_stochastic_visibility_walk"
LANGUAGE_PATHS = {
    "c": "c/p/triangulation_stochastic_visibility_walk.c",
    "c3": "c3/p/triangulation_stochastic_visibility_walk.c3",
    "cpp": "cpp/p/triangulation_stochastic_visibility_walk.cpp",
    "elisa": "elisa/p/triangulation_stochastic_visibility_walk.elisa",
    "mojo": "mojo/p/triangulation_stochastic_visibility_walk.mojo",
    "nim": "nim/p/triangulation_stochastic_visibility_walk.nim",
    "odin": "odin/p/triangulation_stochastic_visibility_walk.odin",
    "rust": "rust/p/triangulation_stochastic_visibility_walk.rs",
    "v": "v/p/triangulation_stochastic_visibility_walk.v",
    "zig": "zig/p/triangulation_stochastic_visibility_walk.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    inventory_path = PACKAGE / "INVENTORY.json"
    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm name does not match the package")
    if inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory function symbol does not match the package")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI is not i64_array_scalar")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory language map does not list exactly the ten expected ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file():
        contents = readme.read_text(encoding="utf-8")
        for required in ("10.1007/978-1-4939-2864-4_587", "10.1142/S0129054102001047",
                         "choice tape", "step_cap", "kirkpatrick_hierarchical_point_location",
                         "point_location_sweep"):
            if required not in contents:
                issues.append(f"README is missing required provenance/contract text: {required}")
    return issues
