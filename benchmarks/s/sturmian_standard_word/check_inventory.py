"""Static package metadata and source inventory checks; ports are not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "sturmian_standard_word"
PORTS = {
    "c": "c/s/sturmian_standard_word.c",
    "c3": "c3/s/sturmian_standard_word.c3",
    "cpp": "cpp/s/sturmian_standard_word.cpp",
    "elisa": "elisa/s/sturmian_standard_word.elisa",
    "mojo": "mojo/s/sturmian_standard_word.mojo",
    "nim": "nim/s/sturmian_standard_word.nim",
    "odin": "odin/s/sturmian_standard_word.odin",
    "rust": "rust/s/sturmian_standard_word.rs",
    "v": "v/s/sturmian_standard_word.v",
    "zig": "zig/s/sturmian_standard_word.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    package_files = (
        "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py", "check_inventory.py",
    )
    for name in package_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol: {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "view[i64]" not in source):
            issues.append("Elisa port must keep raw pointers out of its internal algorithm")
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
    input_meta = workload.get("input", {})
    if (bounds.get("maximum_steps") != 4
            or bounds.get("maximum_valid_input_length") != 5
            or bounds.get("maximum_parseable_input_length") != 6
            or bounds.get("maximum_output_bytes") != 41
            or bounds.get("workspace_bytes") != 512
            or input_meta.get("maximum_valid_input_length") != 5
            or input_meta.get("maximum_parseable_input_length") != 6
            or workload.get("output", {}).get("maximum_output_bytes") != 41
            or workload.get("workspace", {}).get("bytes") != 512):
        issues.append("inventory/workload bounds differ from the profile")
    return issues


if __name__ == "__main__":
    errors = static_issues()
    if errors:
        raise SystemExit("\n".join(errors))
