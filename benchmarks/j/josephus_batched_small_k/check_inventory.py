"""Static inventory checks; does not import or execute benchmark ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "josephus_batched_small_k"
SOURCE = "https://en.oi-wiki.org/misc/josephus/"
PORTS = {
    "c": "c/j/josephus_batched_small_k.c",
    "c3": "c3/j/josephus_batched_small_k.c3",
    "cpp": "cpp/j/josephus_batched_small_k.cpp",
    "elisa": "elisa/j/josephus_batched_small_k.elisa",
    "mojo": "mojo/j/josephus_batched_small_k.mojo",
    "nim": "nim/j/josephus_batched_small_k.nim",
    "odin": "odin/j/josephus_batched_small_k.odin",
    "rust": "rust/j/josephus_batched_small_k.rs",
    "v": "v/j/josephus_batched_small_k.v",
    "zig": "zig/j/josephus_batched_small_k.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)


def static_issues() -> list[str]:
    issues = [f"missing artifact: {name}" for name in REQUIRED if not (PACKAGE / name).is_file()]
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    for language, relative in PORTS.items():
        port = ROOT / relative
        if not port.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if SYMBOL not in port.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {relative}")
        if relative not in inventory:
            issues.append(f"inventory does not list {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README does not link {relative}")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload symbol metadata mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    if workload.get("source", {}).get("url") != SOURCE:
        issues.append("workload source URL mismatch")
    if SOURCE not in readme or SOURCE not in (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8"):
        issues.append("source citation missing from package docs")
    cases = workload.get("cases", [])
    if len(cases) < 10:
        issues.append("workload has fewer than ten fixtures")
    for case in cases:
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"invalid fixture input metadata: {case.get('id')}")
        if type(case.get("expected_result")) is not int:
            issues.append(f"fixture lacks scalar expected result: {case.get('id')}")
    return issues
