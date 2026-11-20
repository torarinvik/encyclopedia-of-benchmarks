"""Static package inventory checks; this module does not build or run ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "zwick_deterministic_bridging_set"
LANGUAGES = {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or symbol differs")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI differs")
    if inventory.get("workspace_bytes") != 4096:
        issues.append("inventory workspace differs")
    if workload.get("algorithm") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        issues.append("workload algorithm or symbol differs")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI differs")
    if workload.get("input", {}).get("maximum_valid_length") != 130:
        issues.append("workload maximum valid input length differs")
    if workload.get("input", {}).get("maximum_parseable_length") != 131:
        issues.append("workload maximum parseable input length differs")
    if workload.get("workspace", {}).get("bytes") != 4096:
        issues.append("workload workspace differs")
    languages = inventory.get("languages", {})
    if set(languages) != LANGUAGES:
        issues.append("inventory must list exactly the ten supported languages")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read README: {error}"]
    for language, relative in languages.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README path differs from inventory for {language}")
    for artifact in inventory.get("metadata", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
