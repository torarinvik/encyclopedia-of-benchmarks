"""Static path and metadata checks; this module is not run in quiet mode."""

import json
from pathlib import Path

PACKAGE = Path(__file__).parent
ROOT = PACKAGE.parents[2]


def static_issues():
    issues = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    for rel in inventory["source_paths"]:
        if not (ROOT / rel).is_file():
            issues.append(f"missing source port: {rel}")
    for rel in inventory["artifacts"]:
        if not (PACKAGE / rel).is_file():
            issues.append(f"missing package artifact: {rel}")
    if len(inventory["source_paths"]) != 10 or len(set(inventory["source_paths"])) != 10:
        issues.append("inventory must list ten distinct language ports")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload and inventory algorithm IDs differ")
    if workload.get("abi") != inventory.get("abi"):
        issues.append("workload and inventory ABIs differ")
    if workload.get("input", {}).get("maximum_valid_length") != inventory.get("input_bounds", {}).get("max_valid_words"):
        issues.append("valid input bound differs between workload and inventory")
    if workload.get("input", {}).get("maximum_parseable_length") != inventory.get("input_bounds", {}).get("max_parseable_words"):
        issues.append("parseable input bound differs between workload and inventory")
    if workload.get("output", {}).get("maximum_bytes") != inventory.get("output_bounds", {}).get("max_bytes"):
        issues.append("output bound differs between workload and inventory")
    if workload.get("workspace", {}).get("bytes") != inventory.get("workspace_bytes"):
        issues.append("workspace bound differs between workload and inventory")
    case_ids = {case.get("id") for case in workload.get("cases", [])}
    required_cases = {
        "three-equal-symbols-leftmost-tie",
        "maximum-eight-symbol-frame-and-output",
        "maximum-output-one-byte-short",
        "maximum-parseable-frame-trailing-word",
        "null-input",
        "null-output",
    }
    missing_cases = required_cases - case_ids
    if missing_cases:
        issues.append(f"required workload cases are missing: {sorted(missing_cases)}")
    return issues


def check_inventory():
    return static_issues()


if __name__ == "__main__":
    errors = static_issues()
    if errors:
        raise SystemExit("\n".join(errors))
