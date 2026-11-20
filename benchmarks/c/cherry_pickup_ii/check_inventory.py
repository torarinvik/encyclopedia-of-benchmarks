"""Static package inventory review; this API never executes language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "cherry_pickup_ii"
PORTS = {
    "c": ROOT / "c/c/cherry_pickup_ii.c",
    "c3": ROOT / "c3/c/cherry_pickup_ii.c3",
    "cpp": ROOT / "cpp/c/cherry_pickup_ii.cpp",
    "elisa": ROOT / "elisa/c/cherry_pickup_ii.elisa",
    "mojo": ROOT / "mojo/c/cherry_pickup_ii.mojo",
    "nim": ROOT / "nim/c/cherry_pickup_ii.nim",
    "odin": ROOT / "odin/c/cherry_pickup_ii.odin",
    "rust": ROOT / "rust/c/cherry_pickup_ii.rs",
    "v": ROOT / "v/c/cherry_pickup_ii.v",
    "zig": ROOT / "zig/c/cherry_pickup_ii.zig",
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
    if contract.get("rows_range") != [2, 6] or contract.get("columns_range") != [2, 6]:
        issues.append("dimension bounds mismatch")
    if contract.get("exact_length") != "2+rows*columns":
        issues.append("frame formula mismatch")
    if contract.get("maximum_valid_length") != 38 or contract.get("maximum_parseable_length") != 39:
        issues.append("maximum frame bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases are missing")
    else:
        seen: set[str] = set()
        for case in cases:
            if not isinstance(case, dict):
                issues.append("workload contains a non-object case")
                continue
            case_id = case.get("id")
            values = case.get("input_values")
            if not isinstance(case_id, str) or case_id in seen:
                issues.append("fixture IDs must be unique strings")
            seen.add(case_id)
            if not isinstance(values, list) or case.get("input_length") != len(values):
                issues.append(f"fixture length mismatch: {case_id}")
            if isinstance(values, list) and len(values) > 39:
                issues.append(f"fixture exceeds parseable frame: {case_id}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {language} port")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    readme = PACKAGE / "README.md"
    if readme.is_file() and "leetcode.com/problems/cherry-pickup-ii/" not in readme.read_text(encoding="utf-8"):
        issues.append("README missing official problem provenance")
    return issues
