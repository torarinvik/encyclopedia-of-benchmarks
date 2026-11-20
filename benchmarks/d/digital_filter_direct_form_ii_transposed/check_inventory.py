"""Static package inventory check; it does not invoke programs or compilers."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "digital_filter_direct_form_ii_transposed"
PORTS = {
    "c": "c/d/digital_filter_direct_form_ii_transposed.c",
    "c3": "c3/d/digital_filter_direct_form_ii_transposed.c3",
    "cpp": "cpp/d/digital_filter_direct_form_ii_transposed.cpp",
    "elisa": "elisa/d/digital_filter_direct_form_ii_transposed.elisa",
    "mojo": "mojo/d/digital_filter_direct_form_ii_transposed.mojo",
    "nim": "nim/d/digital_filter_direct_form_ii_transposed.nim",
    "odin": "odin/d/digital_filter_direct_form_ii_transposed.odin",
    "rust": "rust/d/digital_filter_direct_form_ii_transposed.rs",
    "v": "v/d/digital_filter_direct_form_ii_transposed.v",
    "zig": "zig/d/digital_filter_direct_form_ii_transposed.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py", "check_inventory.py",
    ):
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
        if language == "elisa" and ("view[i64]" not in source or "UnsafePointer" in source):
            issues.append("Elisa port must use a bounded borrowed input view")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or language-port list differs")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_order") != 4
            or bounds.get("maximum_sample_count") != 32
            or bounds.get("maximum_valid_input_length") != 44
            or bounds.get("maximum_parseable_input_length") != 45
            or bounds.get("maximum_output_bytes") != 256
            or bounds.get("workspace_bytes") != 256
            or workload.get("input", {}).get("maximum_valid_input_length") != 44
            or workload.get("input", {}).get("maximum_parseable_input_length") != 45
            or workload.get("output", {}).get("maximum_output_bytes") != 256
            or workload.get("workspace", {}).get("bytes") != 256):
        issues.append("inventory/workload bounds differ from the bounded profile")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
