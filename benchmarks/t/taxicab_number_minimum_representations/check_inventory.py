"""Static package inventory helper; it does not execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "taxicab_number_minimum_representations"
SOURCE = "https://cs.uwaterloo.ca/journals/JIS/VOL11/Boyer/boyer.html"
PORTS = {
    "c": "c/t/taxicab_number_minimum_representations.c",
    "c3": "c3/t/taxicab_number_minimum_representations.c3",
    "cpp": "cpp/t/taxicab_number_minimum_representations.cpp",
    "elisa": "elisa/t/taxicab_number_minimum_representations.elisa",
    "mojo": "mojo/t/taxicab_number_minimum_representations.mojo",
    "nim": "nim/t/taxicab_number_minimum_representations.nim",
    "odin": "odin/t/taxicab_number_minimum_representations.odin",
    "rust": "rust/t/taxicab_number_minimum_representations.rs",
    "v": "v/t/taxicab_number_minimum_representations.v",
    "zig": "zig/t/taxicab_number_minimum_representations.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues = [f"missing artifact: {name}" for name in REQUIRED if not (PACKAGE / name).is_file()]
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol: {relative}")
        if relative not in inventory:
            issues.append(f"inventory omits {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README omits {language} path")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    if workload.get("source", {}).get("reference_url") != SOURCE:
        issues.append("workload primary citation mismatch")
    if SOURCE not in readme or SOURCE not in rights:
        issues.append("primary citation missing from docs")
    cases = workload.get("cases", [])
    if len(cases) < 8:
        issues.append("fewer than eight workload fixtures")
    for case in cases:
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"invalid fixture framing: {case.get('id')}")
        if type(case.get("expected_result")) is not int:
            issues.append(f"fixture lacks integer result: {case.get('id')}")
    return issues
