"""Static package/path/metadata inspection; never invokes benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "squfof_semiprime_factor"
PORTS = {
    "c": "c/s/squfof_semiprime_factor.c",
    "c3": "c3/s/squfof_semiprime_factor.c3",
    "cpp": "cpp/s/squfof_semiprime_factor.cpp",
    "elisa": "elisa/s/squfof_semiprime_factor.elisa",
    "mojo": "mojo/s/squfof_semiprime_factor.mojo",
    "nim": "nim/s/squfof_semiprime_factor.nim",
    "odin": "odin/s/squfof_semiprime_factor.odin",
    "rust": "rust/s/squfof_semiprime_factor.rs",
    "v": "v/s/squfof_semiprime_factor.v",
    "zig": "zig/s/squfof_semiprime_factor.zig",
}
EXPECTED_CASES = {
    "first-even-square-15", "first-even-square-35", "nontrivial-square-root-77",
    "later-square-and-two-reverse-steps", "prime-bounded-miss", "square-input-shortcut",
    "zero-forward-budget", "zero-reverse-budget", "maximum-cap-success", "trailing-word",
    "number-below-range", "even-number", "number-above-range", "negative-forward-cap",
    "forward-cap-too-large", "negative-reverse-cap", "reverse-cap-too-large", "null-input",
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
    input_spec = workload.get("input", {})
    case_ids = {case.get("id") for case in workload.get("cases", []) if isinstance(case, dict)}
    if (bounds.get("maximum_number") != 1_000_000_000_000
            or bounds.get("forward_cap") != [0, 256]
            or bounds.get("reverse_cap") != [0, 256]
            or bounds.get("maximum_valid_input_length") != 3
            or bounds.get("maximum_parseable_input_length") != 4
            or bounds.get("workspace_bytes") != 512
            or input_spec.get("maximum_valid_length") != 3
            or input_spec.get("maximum_parseable_length") != 4
            or workload.get("workspace", {}).get("bytes") != 512
            or case_ids != EXPECTED_CASES):
        issues.append("inventory/workload bounds or fixture list differ from the package contract")
    return issues


if __name__ == "__main__":
    for issue in static_issues():
        print(issue)
    if not static_issues():
        print("SQUFOF package inventory is complete")
