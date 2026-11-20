"""Static package inventory checks; no program or compiler is invoked."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "chess960_scharnagl_position_unrank"
PORTS = {
    "c": "c/c/chess960_scharnagl_position_unrank.c",
    "c3": "c3/c/chess960_scharnagl_position_unrank.c3",
    "cpp": "cpp/c/chess960_scharnagl_position_unrank.cpp",
    "elisa": "elisa/c/chess960_scharnagl_position_unrank.elisa",
    "mojo": "mojo/c/chess960_scharnagl_position_unrank.mojo",
    "nim": "nim/c/chess960_scharnagl_position_unrank.nim",
    "odin": "odin/c/chess960_scharnagl_position_unrank.odin",
    "rust": "rust/c/chess960_scharnagl_position_unrank.rs",
    "v": "v/c/chess960_scharnagl_position_unrank.v",
    "zig": "zig/c/chess960_scharnagl_position_unrank.zig",
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
            issues.append(f"missing port: {relative}")
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
        issues.append("inventory identity or native port list differs")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_batch_size") != 960
            or bounds.get("maximum_valid_input_length") != 961
            or bounds.get("maximum_parseable_input_length") != 962
            or bounds.get("maximum_output_bytes") != 7680
            or bounds.get("workspace_bytes") != 192
            or workload.get("input", {}).get("maximum_valid_input_length") != 961
            or workload.get("input", {}).get("maximum_parseable_input_length") != 962
            or workload.get("output", {}).get("maximum_output_bytes") != 7680
            or workload.get("workspace", {}).get("bytes") != 192):
        issues.append("inventory/workload bounds differ from the bounded profile")
    cases = workload.get("cases", [])
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    empty = by_id.get("empty_batch_accepts_null_output", {})
    if (empty.get("input_values") != [0]
            or empty.get("input_length") != 1
            or empty.get("output_is_null") is not True
            or empty.get("expected_result") != 0):
        issues.append("zero-byte null-output fixture is missing or inconsistent")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
