"""Check package paths and static workload bounds without native execution."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]


def static_issues() -> list[str]:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if (inventory.get("algorithm") != "jury_discrete_time_stability_predicate"
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("status") != "integrated"
            or inventory.get("suite_status") != "integrated"):
        issues.append("inventory identity, ABI, or integration status differs")
    if (workload.get("algorithm") != "jury_discrete_time_stability_predicate"
            or workload.get("function_symbol") != "jury_discrete_time_stability_predicate"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    for relative in inventory["package_files"]:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file: {relative}")
    for relative in inventory["native_paths"]:
        if not (ROOT / relative).is_file():
            issues.append(f"missing native source: {relative}")
    maximum_parseable = workload["input"]["maximum_parseable_input_length"]
    maximum_valid = workload["input"]["maximum_valid_input_length"]
    if maximum_valid != 6 or maximum_parseable != 7:
        issues.append("workload input frame bounds differ from the package contract")
    for case in workload["cases"]:
        if case["input_length"] != len(case["input_values"]):
            issues.append(f"{case['id']}: input_length differs from fixture size")
        if case["input_length"] > maximum_parseable:
            issues.append(f"{case['id']}: exceeds parseable input bound")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
