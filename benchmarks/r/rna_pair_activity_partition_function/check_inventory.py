"""Check source paths, package artifacts, and integration metadata statically."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "rna_pair_activity_partition_function"
PORTS = {
    "c": "c/r/rna_pair_activity_partition_function.c",
    "c3": "c3/r/rna_pair_activity_partition_function.c3",
    "cpp": "cpp/r/rna_pair_activity_partition_function.cpp",
    "elisa": "elisa/r/rna_pair_activity_partition_function.elisa",
    "mojo": "mojo/r/rna_pair_activity_partition_function.mojo",
    "nim": "nim/r/rna_pair_activity_partition_function.nim",
    "odin": "odin/r/rna_pair_activity_partition_function.odin",
    "rust": "rust/r/rna_pair_activity_partition_function.rs",
    "v": "v/r/rna_pair_activity_partition_function.v",
    "zig": "zig/r/rna_pair_activity_partition_function.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("status") != "integrated"
            or inventory.get("suite_status") != "integrated"):
        issues.append("inventory identity, ABI, or integration status differs")
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if set(inventory.get("native_paths", ())) != set(PORTS.values()):
        issues.append("inventory native paths differ from the supported language ports")
    for relative in inventory.get("package_files", ()):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file: {relative}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol is missing from {relative}")
    if "10.1002/bip.360290621" not in readme or "10.1007/978-1-4939-2864-4_345" not in readme:
        issues.append("primary RNA partition sources are missing from package documentation")
    return issues
