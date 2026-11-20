"""Static source and metadata inventory checks; no native port is executed."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "recursive_backtracker_maze_generation"
PORTS = {
    "c": "c/r/recursive_backtracker_maze_generation.c",
    "c3": "c3/r/recursive_backtracker_maze_generation.c3",
    "cpp": "cpp/r/recursive_backtracker_maze_generation.cpp",
    "elisa": "elisa/r/recursive_backtracker_maze_generation.elisa",
    "mojo": "mojo/r/recursive_backtracker_maze_generation.mojo",
    "nim": "nim/r/recursive_backtracker_maze_generation.nim",
    "odin": "odin/r/recursive_backtracker_maze_generation.odin",
    "rust": "rust/r/recursive_backtracker_maze_generation.rs",
    "v": "v/r/recursive_backtracker_maze_generation.v",
    "zig": "zig/r/recursive_backtracker_maze_generation.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    package_files = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py", "check_inventory.py",
    )
    for name in package_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol: {relative}")
        if language == "elisa" and ("view[i64]" not in source or "UnsafePointer" in source):
            issues.append("Elisa port must use a bounded borrowed input view, not raw pointers")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or native port list differs")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_valid_input_length") != 67
            or bounds.get("maximum_parseable_input_length") != 68
            or bounds.get("maximum_output_bytes") != 64
            or bounds.get("workspace_bytes") != 1024
            or workload.get("input", {}).get("maximum_valid_input_length") != 67
            or workload.get("input", {}).get("maximum_parseable_input_length") != 68
            or workload.get("output", {}).get("maximum_output_bytes") != 64
            or workload.get("workspace", {}).get("bytes") != 1024):
        issues.append("inventory/workload bounds differ from the bounded profile")
    case_list = workload.get("cases", [])
    by_id = {case.get("id"): case for case in case_list if isinstance(case, dict)}
    maximum = by_id.get("maximum_cell_count_short_output", {})
    if (maximum.get("input_length") != 67
            or len(maximum.get("input_values", [])) != 67
            or maximum.get("output_capacity") != 63
            or maximum.get("expected_result") != -2):
        issues.append("maximum valid frame/capacity fixture is missing or inconsistent")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
