"""Static package and port inventory checks; this module executes no port."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "snake_case_to_camel_pascal_case"
PORTS = {
    "c": "c/s/snake_case_to_camel_pascal_case.c",
    "c3": "c3/s/snake_case_to_camel_pascal_case.c3",
    "cpp": "cpp/s/snake_case_to_camel_pascal_case.cpp",
    "elisa": "elisa/s/snake_case_to_camel_pascal_case.elisa",
    "mojo": "mojo/s/snake_case_to_camel_pascal_case.mojo",
    "nim": "nim/s/snake_case_to_camel_pascal_case.nim",
    "odin": "odin/s/snake_case_to_camel_pascal_case.odin",
    "rust": "rust/s/snake_case_to_camel_pascal_case.rs",
    "v": "v/s/snake_case_to_camel_pascal_case.v",
    "zig": "zig/s/snake_case_to_camel_pascal_case.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol: {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "view[i64]" not in source):
            issues.append("Elisa port must use a bounded borrowed input view")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    bounds = inventory.get("bounds", {})
    input_meta = workload.get("input", {})
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or native port list differs")
    if (bounds.get("maximum_valid_input_length") != 257
            or bounds.get("maximum_parseable_input_length") != 258
            or bounds.get("maximum_output_bytes") != 256
            or bounds.get("workspace_bytes") != 256
            or input_meta.get("maximum_valid_length") != 257
            or input_meta.get("maximum_parseable_length") != 258
            or workload.get("output", {}).get("maximum_bytes") != 256
            or workload.get("workspace", {}).get("bytes") != 256):
        issues.append("inventory/workload bounds differ from the byte-output profile")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
