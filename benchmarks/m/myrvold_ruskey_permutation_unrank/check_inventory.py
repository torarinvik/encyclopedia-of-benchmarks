"""Static package and inventory review; this checker is intentionally unrun."""

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

    if inventory.get("algorithm") != "myrvold_ruskey_permutation_unrank":
        issues.append("inventory algorithm name is incorrect")
    if inventory.get("abi") != "i64_array_bytes_output":
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
        issues.append("inventory artifact list does not match the package requirements")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload algorithm differs from inventory")
    if workload.get("abi") != inventory.get("abi"):
        issues.append("workload ABI differs from inventory")
    if inventory.get("workspace_bytes") != workload.get("workspace", {}).get("bytes"):
        issues.append("inventory and workload workspace caps differ")
    for key, workload_key in (("max_valid_input_length", "maximum_valid_length"),
                              ("max_parseable_input_length", "maximum_parseable_length"),
                              ("max_output_bytes", "maximum_output_bytes")):
        source = "input" if "input" in key else "output"
        if inventory.get(key) != workload.get(source, {}).get(workload_key):
            issues.append(f"inventory and workload {key} differ")
    return issues


if __name__ == "__main__":
    for issue in static_issues():
        print(issue)
