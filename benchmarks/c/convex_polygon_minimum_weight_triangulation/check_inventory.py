"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "convex_polygon_minimum_weight_triangulation"
LANGUAGE_PATHS = {
    "c": "c/c/convex_polygon_minimum_weight_triangulation.c",
    "c3": "c3/c/convex_polygon_minimum_weight_triangulation.c3",
    "cpp": "cpp/c/convex_polygon_minimum_weight_triangulation.cpp",
    "elisa": "elisa/c/convex_polygon_minimum_weight_triangulation.elisa",
    "mojo": "mojo/c/convex_polygon_minimum_weight_triangulation.mojo",
    "nim": "nim/c/convex_polygon_minimum_weight_triangulation.nim",
    "odin": "odin/c/convex_polygon_minimum_weight_triangulation.odin",
    "rust": "rust/c/convex_polygon_minimum_weight_triangulation.rs",
    "v": "v/c/convex_polygon_minimum_weight_triangulation.v",
    "zig": "zig/c/convex_polygon_minimum_weight_triangulation.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or function symbol does not match the package")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI is not i64_array_scalar")
    if (inventory.get("workspace_bytes") != 2048
            or inventory.get("maximum_input_words") != 36
            or inventory.get("maximum_parseable_words") != 37
            or inventory.get("maximum_result") != 7000):
        issues.append("inventory bounds do not match the package contract")
    if inventory.get("primary_reference") != "primary_oracle.py":
        issues.append("inventory primary reference is missing or incorrect")
    if inventory.get("independent_reference") != "independent_oracle.py":
        issues.append("inventory independent reference is missing or incorrect")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten expected language ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        source = ROOT / relative_path
        if not source.is_file():
            issues.append(f"missing {language} source: {relative_path}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"entrypoint name is missing from {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file():
        contents = readme.read_text(encoding="utf-8")
        for required in (
            "10.1007/978-1-4939-2864-4_715",
            "10.1016/S0167-5060(08)70044-X",
            "n(n-3)/2",
            "Catalan",
            "supplied integer weights",
        ):
            if required not in contents:
                issues.append(f"README is missing required source/contract text: {required}")
    return issues
