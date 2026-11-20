"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/z/zielonka_parity_game_solver"
ALGORITHM = "zielonka_parity_game_solver"
LANGUAGE_PATHS = {
    "c": "c/z/zielonka_parity_game_solver.c",
    "c3": "c3/z/zielonka_parity_game_solver.c3",
    "cpp": "cpp/z/zielonka_parity_game_solver.cpp",
    "elisa": "elisa/z/zielonka_parity_game_solver.elisa",
    "mojo": "mojo/z/zielonka_parity_game_solver.mojo",
    "nim": "nim/z/zielonka_parity_game_solver.nim",
    "odin": "odin/z/zielonka_parity_game_solver.odin",
    "rust": "rust/z/zielonka_parity_game_solver.rs",
    "v": "v/z/zielonka_parity_game_solver.v",
    "zig": "zig/z/zielonka_parity_game_solver.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or symbol does not match the package")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI is not i64_array_scalar")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten expected ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file():
        contents = readme.read_text(encoding="utf-8")
        for required in ("10.1007/978-1-4939-2864-4_591", "10.1016/0168-0072(93)90036-D",
                         "minimum", "Even", "Odd", "games_on_arbitrary_graphs"):
            if required not in contents:
                issues.append(f"README is missing required source/contract text: {required}")
    return issues
