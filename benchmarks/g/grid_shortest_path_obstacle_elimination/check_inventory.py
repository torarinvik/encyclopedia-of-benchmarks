"""Static source and metadata inventory checks; no port is executed."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "grid_shortest_path_obstacle_elimination"
PORTS = {
    "c": "c/g/grid_shortest_path_obstacle_elimination.c",
    "c3": "c3/g/grid_shortest_path_obstacle_elimination.c3",
    "cpp": "cpp/g/grid_shortest_path_obstacle_elimination.cpp",
    "elisa": "elisa/g/grid_shortest_path_obstacle_elimination.elisa",
    "mojo": "mojo/g/grid_shortest_path_obstacle_elimination.mojo",
    "nim": "nim/g/grid_shortest_path_obstacle_elimination.nim",
    "odin": "odin/g/grid_shortest_path_obstacle_elimination.odin",
    "rust": "rust/g/grid_shortest_path_obstacle_elimination.rs",
    "v": "v/g/grid_shortest_path_obstacle_elimination.v",
    "zig": "zig/g/grid_shortest_path_obstacle_elimination.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                 "workload.json", "primary_oracle.py", "independent_oracle.py",
                 "verify_workload.py", "check_inventory.py"):
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
            issues.append("Elisa port must use a bounded input view without UnsafePointer")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or port list differs")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_valid_input_length") != 39
            or bounds.get("maximum_parseable_input_length") != 40
            or bounds.get("maximum_states") != 252
            or bounds.get("workspace_bytes") != 8192
            or workload.get("input", {}).get("maximum_valid_input_length") != 39
            or workload.get("input", {}).get("maximum_parseable_input_length") != 40
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("inventory/workload bounds differ from the profile")
    cases = workload.get("cases", [])
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum = by_id.get("maximum_frame_open_grid", {})
    overlong = by_id.get("maximum_parseable_trailing_word", {})
    if (maximum.get("input_length") != 39
            or len(maximum.get("input_values", [])) != 39
            or maximum.get("expected_result") != 10
            or overlong.get("input_length") != 40
            or len(overlong.get("input_values", [])) != 40
            or overlong.get("expected_result") != -2):
        issues.append("maximum valid/parseable frame fixtures are missing or inconsistent")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
