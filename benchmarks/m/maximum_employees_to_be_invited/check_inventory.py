"""Static package inventory review; this module does not execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "maximum_employees_to_be_invited"
PORTS = {
    "c": ROOT / "c/m/maximum_employees_to_be_invited.c",
    "c3": ROOT / "c3/m/maximum_employees_to_be_invited.c3",
    "cpp": ROOT / "cpp/m/maximum_employees_to_be_invited.cpp",
    "elisa": ROOT / "elisa/m/maximum_employees_to_be_invited.elisa",
    "mojo": ROOT / "mojo/m/maximum_employees_to_be_invited.mojo",
    "nim": ROOT / "nim/m/maximum_employees_to_be_invited.nim",
    "odin": ROOT / "odin/m/maximum_employees_to_be_invited.odin",
    "rust": ROOT / "rust/m/maximum_employees_to_be_invited.rs",
    "v": ROOT / "v/m/maximum_employees_to_be_invited.v",
    "zig": ROOT / "zig/m/maximum_employees_to_be_invited.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm or exported symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    contract = workload.get("input", {})
    if contract.get("n_range") != [2, 8] or contract.get("exact_length") != "n+1":
        issues.append("input bounds or framing mismatch")
    if contract.get("maximum_valid_length") != 9 or contract.get("maximum_parseable_length") != 10:
        issues.append("maximum input bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases are missing")
    else:
        ids: set[str] = set()
        for case in cases:
            if not isinstance(case, dict):
                issues.append("workload contains a non-object fixture")
                continue
            case_id = case.get("id")
            values = case.get("input_values")
            if not isinstance(case_id, str) or case_id in ids:
                issues.append("fixture IDs must be unique strings")
            ids.add(case_id)
            if not isinstance(values, list) or case.get("input_length") != len(values):
                issues.append(f"fixture length mismatch: {case_id}")
            if isinstance(values, list) and len(values) > 10:
                issues.append(f"fixture exceeds parseable input bound: {case_id}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {language} port")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file():
        text = readme.read_text(encoding="utf-8")
        if "https://leetcode.com/problems/maximum-employees-to-be-invited-to-a-meeting/" not in text:
            issues.append("README missing official problem provenance")
        if "two-person circle" not in text:
            issues.append("README missing the two-person adjacency rule")
    return issues
