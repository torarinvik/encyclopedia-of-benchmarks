"""Static package and inventory review; intentionally not executed."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE_DIR = Path(__file__).resolve().parent
LANGUAGES = {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}
ARTIFACTS = {
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "primary_oracle.py", "independent_oracle.py", "workload.json",
    "verify_workload.py", "check_inventory.py",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE_DIR / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE_DIR / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "k_ary_huffman_weighted_path_cost":
        issues.append("inventory algorithm name is incorrect")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI is incorrect")
    if set(inventory.get("languages", {})) != LANGUAGES:
        issues.append("inventory must list exactly the ten supported languages")
    for language, relative_path in inventory.get("languages", {}).items():
        if not isinstance(relative_path, str) or not (PACKAGE_DIR / relative_path).is_file():
            issues.append(f"missing {language} source path: {relative_path!r}")
    for artifact in ARTIFACTS:
        if not (PACKAGE_DIR / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    if set(inventory.get("artifacts", [])) != ARTIFACTS:
        issues.append("inventory artifact list differs from required package files")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload algorithm differs from inventory")
    if workload.get("function_symbol") != inventory.get("function_symbol"):
        issues.append("workload function symbol differs from inventory")
    if workload.get("abi") != inventory.get("abi"):
        issues.append("workload ABI differs from inventory")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if inventory.get("max_valid_input_length") != input_meta.get("maximum_valid_length"):
        issues.append("maximum valid input length differs between inventory and workload")
    if inventory.get("max_parseable_input_length") != input_meta.get("maximum_parseable_length"):
        issues.append("maximum parseable input length differs between inventory and workload")
    if inventory.get("max_result") != output_meta.get("valid_result_range", [None, None])[1]:
        issues.append("maximum result differs between inventory and workload")
    if inventory.get("workspace_bytes") != workload.get("workspace", {}).get("bytes"):
        issues.append("workspace cap differs between inventory and workload")
    return issues

