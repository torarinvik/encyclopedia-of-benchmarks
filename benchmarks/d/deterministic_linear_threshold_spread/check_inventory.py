"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/d/deterministic_linear_threshold_spread"
ALGORITHM = "deterministic_linear_threshold_spread"
LANGUAGE_PATHS = {
    "c": "c/d/deterministic_linear_threshold_spread.c",
    "c3": "c3/d/deterministic_linear_threshold_spread.c3",
    "cpp": "cpp/d/deterministic_linear_threshold_spread.cpp",
    "elisa": "elisa/d/deterministic_linear_threshold_spread.elisa",
    "mojo": "mojo/d/deterministic_linear_threshold_spread.mojo",
    "nim": "nim/d/deterministic_linear_threshold_spread.nim",
    "odin": "odin/d/deterministic_linear_threshold_spread.odin",
    "rust": "rust/d/deterministic_linear_threshold_spread.rs",
    "v": "v/d/deterministic_linear_threshold_spread.v",
    "zig": "zig/d/deterministic_linear_threshold_spread.zig",
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
    if inventory.get("workspace_bytes") != 2048:
        issues.append("inventory workspace bound does not match the package contract")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten expected language ports")
    if (inventory.get("maximum_input_words") != 91
            or inventory.get("maximum_parseable_words") != 92
            or inventory.get("maximum_output_bytes") != 80):
        issues.append("inventory bounds do not match the package contract")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file():
        contents = readme.read_text(encoding="utf-8")
        for required in ("10.1007/978-1-4939-2864-4_710", "10.1109/ICDCSW.2011.33",
                         "synchronous", "round", "randomized"):
            if required not in contents:
                issues.append(f"README is missing required source/contract text: {required}")
    return issues
