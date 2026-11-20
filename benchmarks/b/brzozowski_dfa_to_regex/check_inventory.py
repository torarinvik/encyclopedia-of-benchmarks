"""Static package metadata and native-source inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "brzozowski_dfa_to_regex"
PORTS = {
    "c": "c/b/brzozowski_dfa_to_regex.c",
    "c3": "c3/b/brzozowski_dfa_to_regex.c3",
    "cpp": "cpp/b/brzozowski_dfa_to_regex.cpp",
    "elisa": "elisa/b/brzozowski_dfa_to_regex.elisa",
    "mojo": "mojo/b/brzozowski_dfa_to_regex.mojo",
    "nim": "nim/b/brzozowski_dfa_to_regex.nim",
    "odin": "odin/b/brzozowski_dfa_to_regex.odin",
    "rust": "rust/b/brzozowski_dfa_to_regex.rs",
    "v": "v/b/brzozowski_dfa_to_regex.v",
    "zig": "zig/b/brzozowski_dfa_to_regex.zig",
}
PACKAGE_FILES = {
    "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native source: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported function symbol: {relative}")
        if language == "elisa":
            source = path.read_text(encoding="utf-8")
            if "UnsafePointer" in source or "view[i64]" not in source:
                issues.append("Elisa port must use a bounded borrowed input view")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    paths = inventory.get("native_paths", [])
    package_files = inventory.get("package_files", [])
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(paths) != set(PORTS.values())
            or set(package_files) != PACKAGE_FILES):
        issues.append("inventory identity or native source list differs")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_states") != 3
            or bounds.get("maximum_valid_input_length") != 9
            or bounds.get("maximum_parseable_input_length") != 10
            or bounds.get("maximum_regex_bytes") != 270
            or bounds.get("workspace_bytes") != 16384
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != 9
            or workload.get("input", {}).get("maximum_parseable_length") != 10
            or workload.get("output", {}).get("maximum_bytes") != 270
            or workload.get("contract", {}).get("workspace_bytes") != 16384
            or workload.get("source", {}).get("discovery_title") != "Brzozowski algebraic method"
            or workload.get("source", {}).get("discovery_score") != 16
            or workload.get("source", {}).get("discovery_index_line") != 1608):
        issues.append("inventory and workload bounds differ from the contract")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
