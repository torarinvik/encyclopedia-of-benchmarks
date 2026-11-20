"""Static package-file and contract inventory checks; no native code is run."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent


def check_inventory() -> list[str]:
    inventory: dict[str, Any] = json.loads((PACKAGE / "INVENTORY.json").read_text())
    workload: dict[str, Any] = json.loads((PACKAGE / "workload.json").read_text())
    issues: list[str] = []
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    if inventory.get("function_symbol") != "cyclotomic_polynomial_coefficients":
        issues.append("inventory symbol mismatch")
    if len(inventory.get("ports", [])) != 10:
        issues.append("expected ten native ports")
    for relative in inventory.get("ports", []):
        if not (ROOT / relative).is_file():
            issues.append(f"missing port: {relative}")
    for relative in inventory.get("references", []) + inventory.get("static_helpers", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload algorithm mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 248:
        issues.append("workload maximum output bound mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != 1:
        issues.append("workload valid input length mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != 2:
        issues.append("workload parseable input length mismatch")
    if workload.get("input", {}).get("maximum_input_length") != 1:
        issues.append("workload maximum input length mismatch")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 2:
        issues.append("workload maximum parseable input length mismatch")
    return issues


if __name__ == "__main__":
    problems = check_inventory()
    for problem in problems:
        print(problem)
    raise SystemExit(bool(problems))
