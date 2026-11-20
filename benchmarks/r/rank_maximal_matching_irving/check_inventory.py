"""Static package completeness checks; never compiles or executes language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/rank_maximal_matching_irving"
ALGORITHM = "rank_maximal_matching_irving"
LANGUAGE_PATHS = {
    "c": "c/r/rank_maximal_matching_irving.c",
    "c3": "c3/r/rank_maximal_matching_irving.c3",
    "cpp": "cpp/r/rank_maximal_matching_irving.cpp",
    "elisa": "elisa/r/rank_maximal_matching_irving.elisa",
    "mojo": "mojo/r/rank_maximal_matching_irving.mojo",
    "nim": "nim/r/rank_maximal_matching_irving.nim",
    "odin": "odin/r/rank_maximal_matching_irving.odin",
    "rust": "rust/r/rank_maximal_matching_irving.rs",
    "v": "v/r/rank_maximal_matching_irving.v",
    "zig": "zig/r/rank_maximal_matching_irving.zig",
}
METADATA = {
    "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
    "independent_oracle.py", "verify_workload.py", "check_inventory.py",
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
        issues.append("inventory does not list the exact ten language ports")
    if set(inventory.get("metadata", [])) != METADATA:
        issues.append("inventory metadata list is incomplete or contains unexpected entries")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in METADATA | {"INVENTORY.json"}:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    if inventory.get("workspace_bytes") != 1024:
        issues.append("inventory workspace bound must be 1,024 bytes")
    if inventory.get("maximum_input_words") != 51 or inventory.get("maximum_parseable_words") != 52:
        issues.append("inventory input bounds do not match the package contract")
    if inventory.get("maximum_output_bytes") != 40:
        issues.append("inventory output bound must be 40 bytes")
    return issues
