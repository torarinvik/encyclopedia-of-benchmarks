"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "crust_opposite_pole_selection"
LANGUAGE_PATHS = {
    "c": "c/c/crust_opposite_pole_selection.c",
    "c3": "c3/c/crust_opposite_pole_selection.c3",
    "cpp": "cpp/c/crust_opposite_pole_selection.cpp",
    "elisa": "elisa/c/crust_opposite_pole_selection.elisa",
    "mojo": "mojo/c/crust_opposite_pole_selection.mojo",
    "nim": "nim/c/crust_opposite_pole_selection.nim",
    "odin": "odin/c/crust_opposite_pole_selection.odin",
    "rust": "rust/c/crust_opposite_pole_selection.rs",
    "v": "v/c/crust_opposite_pole_selection.v",
    "zig": "zig/c/crust_opposite_pole_selection.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or function symbol does not match the package")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI is not i64_array_bytes_output")
    if inventory.get("workspace_bytes") != 1024:
        issues.append("inventory workspace bound does not match the package contract")
    if (inventory.get("maximum_input_words") != 225
            or inventory.get("maximum_parseable_words") != 226
            or inventory.get("maximum_output_bytes") != 136):
        issues.append("inventory bounds do not match the package contract")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten expected language ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file():
        contents = readme.read_text(encoding="utf-8")
        for required in ("10.1007/978-1-4939-2864-4_713", "10.1145/280814.280947",
                         "negative dot product", "row-local ordinal", "Voronoi"):
            if required not in contents:
                issues.append(f"README is missing required source/contract text: {required}")
    return issues
