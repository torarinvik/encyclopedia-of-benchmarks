"""Static package/path inspection; this module never runs native code."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "gpsr_perimeter_recovery_trace"
PORTS = {
    "c": "c/g/gpsr_perimeter_recovery_trace.c",
    "c3": "c3/g/gpsr_perimeter_recovery_trace.c3",
    "cpp": "cpp/g/gpsr_perimeter_recovery_trace.cpp",
    "elisa": "elisa/g/gpsr_perimeter_recovery_trace.elisa",
    "mojo": "mojo/g/gpsr_perimeter_recovery_trace.mojo",
    "nim": "nim/g/gpsr_perimeter_recovery_trace.nim",
    "odin": "odin/g/gpsr_perimeter_recovery_trace.odin",
    "rust": "rust/g/gpsr_perimeter_recovery_trace.rs",
    "v": "v/g/gpsr_perimeter_recovery_trace.v",
    "zig": "zig/g/gpsr_perimeter_recovery_trace.zig",
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
            issues.append(f"missing native port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol: {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "view[i64]" not in source):
            issues.append("Elisa implementation must use bounded borrowed input views")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity, ABI, or native path list differs")
    bounds = inventory.get("bounds", {})
    in_meta, out_meta = workload.get("input", {}), workload.get("output", {})
    if (bounds.get("maximum_valid_input_length") != 56
            or bounds.get("maximum_parseable_input_length") != 57
            or bounds.get("maximum_output_words") != 112
            or bounds.get("maximum_output_bytes") != 896
            or bounds.get("fixed_payload_accounting_bytes") != 3344
            or bounds.get("workspace_bytes") != 8192
            or in_meta.get("maximum_valid_length") != 56
            or in_meta.get("maximum_parseable_length") != 57
            or out_meta.get("maximum_words") != 112
            or out_meta.get("maximum_bytes") != 896
            or workload.get("workspace", {}).get("fixed_payload_accounting_bytes") != 3344
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("inventory/workload bounds differ from the profile")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
