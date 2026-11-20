"""Static inventory/path/metadata review; it never invokes native code."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "erdos_selfridge_prime_class"
PORTS = {
    "c": "c/e/erdos_selfridge_prime_class.c",
    "c3": "c3/e/erdos_selfridge_prime_class.c3",
    "cpp": "cpp/e/erdos_selfridge_prime_class.cpp",
    "elisa": "elisa/e/erdos_selfridge_prime_class.elisa",
    "mojo": "mojo/e/erdos_selfridge_prime_class.mojo",
    "nim": "nim/e/erdos_selfridge_prime_class.nim",
    "odin": "odin/e/erdos_selfridge_prime_class.odin",
    "rust": "rust/e/erdos_selfridge_prime_class.rs",
    "v": "v/e/erdos_selfridge_prime_class.v",
    "zig": "zig/e/erdos_selfridge_prime_class.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py", "check_inventory.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol in {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "view[i64]" not in source):
            issues.append("Elisa must use a bounded borrowed input view")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or native path list differs")
    bounds = inventory.get("bounds", {})
    input_meta = workload.get("input", {})
    if (bounds.get("maximum_prime") != 100000
            or bounds.get("maximum_selected_neighbor") != 100001
            or bounds.get("maximum_class") != 17
            or bounds.get("maximum_valid_input_length") != 2
            or bounds.get("maximum_parseable_input_length") != 3
            or bounds.get("workspace_bytes") != 4096
            or input_meta.get("prime_range") != [2, 100000]
            or input_meta.get("maximum_valid_input_length") != 2
            or input_meta.get("maximum_parseable_input_length") != 3
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("inventory/workload bounds differ from the package contract")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))

