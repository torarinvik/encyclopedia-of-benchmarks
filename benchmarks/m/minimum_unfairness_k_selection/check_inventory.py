"""Static source/package inventory validator; this file is not run here."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = PACKAGE_DIR.parents[2]
EXPECTED_SYMBOL = "minimum_unfairness_k_selection"


def validate_inventory() -> list[str]:
    inventory = json.loads((PACKAGE_DIR / "inventory.json").read_text(encoding="utf-8"))
    problems: list[str] = []
    if inventory.get("algorithm") != EXPECTED_SYMBOL:
        problems.append("inventory algorithm name does not match the package symbol")
    if inventory.get("abi") != "i64_array_scalar":
        problems.append("inventory ABI is not i64_array_scalar")
    implementations = inventory.get("implementations", {})
    if len(implementations) != 10:
        problems.append("inventory must list all ten language ports")
    for language, relative_path in implementations.items():
        source = REPOSITORY_ROOT / relative_path
        if not source.is_file():
            problems.append(f"missing {language} source: {relative_path}")
        elif EXPECTED_SYMBOL not in source.read_text(encoding="utf-8"):
            problems.append(f"exported symbol is absent from {relative_path}")
    for relative_path in inventory.get("references", []) + inventory.get("metadata", []):
        if not (PACKAGE_DIR / relative_path).is_file():
            problems.append(f"missing package support file: {relative_path}")
    for reference in ("primary_oracle.py", "independent_oracle.py"):
        source = PACKAGE_DIR / reference
        if source.is_file() and "def evaluate(" not in source.read_text(encoding="utf-8"):
            problems.append(f"reference lacks evaluate(): {reference}")
    return problems


def main() -> int:
    problems = validate_inventory()
    if problems:
        for problem in problems:
            print(problem)
        return 1
    print("minimum_unfairness_k_selection package inventory is complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
