"""Statically check package metadata, oracle references, and port presence."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "magic_square_singly_even_strachey"
LANGUAGES = {
    "c": ("c", ".c"),
    "c3": ("c3", ".c3"),
    "cpp": ("cpp", ".cpp"),
    "elisa": ("elisa", ".elisa"),
    "mojo": ("mojo", ".mojo"),
    "nim": ("nim", ".nim"),
    "odin": ("odin", ".odin"),
    "rust": ("rust", ".rs"),
    "v": ("v", ".v"),
    "zig": ("zig", ".zig"),
}
EXPECTED_INPUTS = [6, 10, 14, 30, 2, 8, 7, 34, -(1 << 63), (1 << 63) - 1]


def check_inventory() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package JSON: {error}"]

    if inventory.get("algorithm") != ALGORITHM or workload.get("algorithm") != ALGORITHM:
        issues.append("algorithm identifier does not match the package")
    if inventory.get("abi") != "scalar_call" or workload.get("abi") != "scalar_call":
        issues.append("inventory and workload must declare the scalar_call ABI")
    if inventory.get("function_symbol") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        issues.append("function symbol does not match the exported ABI symbol")
    if workload.get("input", {}).get("minimum_order") != 6 or workload.get("input", {}).get("maximum_order") != 30:
        issues.append("workload order bounds do not match the port contract")
    if workload.get("input", {}).get("valid_orders") != "n % 4 == 2":
        issues.append("workload does not specify the singly-even order predicate")

    provider = workload.get("expected_result_provider", {})
    if (provider.get("module"), provider.get("function")) != ("primary_oracle.py", "expected_result"):
        issues.append("expected-result provider must use primary_oracle.expected_result")
    if (provider.get("cross_check_module"), provider.get("cross_check_function")) != (
        "independent_oracle.py", "expected_result"
    ):
        issues.append("independent oracle reference is missing")
    cases = workload.get("cases", [])
    if [case.get("input_value") for case in cases] != EXPECTED_INPUTS:
        issues.append("workload cases do not match the fixed input profile")
    if len({case.get("id") for case in cases}) != len(cases):
        issues.append("workload case identifiers must be unique")

    ports = inventory.get("ports", {})
    if set(ports) != set(LANGUAGES):
        issues.append("inventory must list exactly the ten supported languages")
    for language, (directory, extension) in LANGUAGES.items():
        expected = ROOT / directory / "m" / f"{ALGORITHM}{extension}"
        relative = ports.get(language)
        if not relative:
            continue
        listed = (PACKAGE / relative).resolve()
        if listed != expected.resolve():
            issues.append(f"{language}: inventory path is not the canonical package port")
        if not listed.is_file():
            issues.append(f"{language}: listed implementation is missing")
        elif ALGORITHM not in listed.read_text(encoding="utf-8"):
            issues.append(f"{language}: source does not declare the package function symbol")

    for name in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"package file is missing: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "https://cs.uwaterloo.ca/journals/JIS/VOL27/Chia/chia6.pdf" not in readme:
        issues.append("README is missing the primary algorithm reference")
    if "https://www.qcc.cuny.edu/engtech/ET_Faculty/Brumgnach/Magic_Squares/Gamma_plus_two_method_for_odd_magic_squares.pdf" not in readme:
        issues.append("README is missing the independent algorithm reference")
    if "rosettagit.org/tasks/" not in rights or "No task statement" not in rights:
        issues.append("rights note must record title-only Rosetta provenance")
    return issues


if __name__ == "__main__":
    problems = check_inventory()
    if problems:
        print("\n".join(problems), file=sys.stderr)
        raise SystemExit(1)
    print("magic_square_singly_even_strachey package inventory is complete")
