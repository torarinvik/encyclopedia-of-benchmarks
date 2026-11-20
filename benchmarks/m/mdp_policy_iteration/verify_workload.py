"""Static metadata and source-inventory review; does not launch any ports."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "mdp_policy_iteration"
LANGUAGE_PATHS = {
    "c": ROOT / "c/m/mdp_policy_iteration.c",
    "c3": ROOT / "c3/m/mdp_policy_iteration.c3",
    "cpp": ROOT / "cpp/m/mdp_policy_iteration.cpp",
    "elisa": ROOT / "elisa/m/mdp_policy_iteration.elisa",
    "mojo": ROOT / "mojo/m/mdp_policy_iteration.mojo",
    "nim": ROOT / "nim/m/mdp_policy_iteration.nim",
    "odin": ROOT / "odin/m/mdp_policy_iteration.odin",
    "rust": ROOT / "rust/m/mdp_policy_iteration.rs",
    "v": ROOT / "v/m/mdp_policy_iteration.v",
    "zig": ROOT / "zig/m/mdp_policy_iteration.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    if (workload.get("input", {}).get("state_count_range") != [1, 4]
            or workload.get("input", {}).get("action_count_range") != [1, 3]
            or workload.get("input", {}).get("maximum_valid_length") != 28):
        issues.append("input bounds mismatch")
    if (workload.get("output", {}).get("maximum_bytes") != 104
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("output or workspace bound mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        length = case.get("input_length", len(values))
        if not isinstance(values, list) or not isinstance(length, int):
            issues.append(f"invalid fixture shape: {case.get('id')}")
            continue
        if not case.get("input_is_null", False) and length != len(values):
            issues.append(f"fixture packed length mismatch: {case.get('id')}")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            issues.append(f"invalid output hex: {case.get('id')}")
            continue
        result = case.get("expected_result")
        if not isinstance(result, int):
            issues.append(f"invalid expected result: {case.get('id')}")
        elif result in (-1, -2) and payload:
            issues.append(f"error case writes output: {case.get('id')}")
        elif result >= 0 and (result != len(payload) or result > 104):
            issues.append(f"success case byte count mismatch: {case.get('id')}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    return issues
