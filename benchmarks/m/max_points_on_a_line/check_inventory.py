"""Static package inventory review; no language port is executed here."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "max_points_on_a_line"
PORTS = {
    "c": ROOT / "c/m/max_points_on_a_line.c",
    "c3": ROOT / "c3/m/max_points_on_a_line.c3",
    "cpp": ROOT / "cpp/m/max_points_on_a_line.cpp",
    "elisa": ROOT / "elisa/m/max_points_on_a_line.elisa",
    "mojo": ROOT / "mojo/m/max_points_on_a_line.mojo",
    "nim": ROOT / "nim/m/max_points_on_a_line.nim",
    "odin": ROOT / "odin/m/max_points_on_a_line.odin",
    "rust": ROOT / "rust/m/max_points_on_a_line.rs",
    "v": ROOT / "v/m/max_points_on_a_line.v",
    "zig": ROOT / "zig/m/max_points_on_a_line.zig",
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
    if contract.get("n_range") != [1, 16] or contract.get("exact_length") != "1+2*n":
        issues.append("input bounds or framing mismatch")
    if contract.get("maximum_valid_length") != 33 or contract.get("maximum_parseable_length") != 34:
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
            if isinstance(values, list) and len(values) > 34:
                issues.append(f"fixture exceeds parseable input bound: {case_id}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {language} port")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
