"""Static package inventory checker; intentionally not run."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/k/k_quadtree_edge_distribution.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
}


def static_issues() -> list[str]:
    issues: list[str] = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if inventory.get("algorithm") != "k_quadtree_edge_distribution":
        issues.append("inventory algorithm ID differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if set(inventory.get("sources", [])) != EXPECTED_SOURCES:
        issues.append("inventory does not list the ten expected language sources")
    for relative in inventory.get("sources", []):
        if not (ROOT / relative).is_file():
            issues.append(f"missing source: {relative}")
    for relative in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file: {relative}")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload and inventory algorithm IDs differ")
    if workload.get("abi") != inventory.get("abi"):
        issues.append("workload and inventory ABI differ")
    for section, workload_key, inventory_key in (
        ("input", "maximum_valid_length", "maximum_valid_input_words"),
        ("input", "maximum_parseable_length", "maximum_parseable_input_words"),
        ("output", "maximum_output_bytes", "maximum_output_bytes"),
        ("workspace", "bytes", "workspace_bytes"),
    ):
        if workload.get(section, {}).get(workload_key) != inventory.get(inventory_key):
            issues.append(f"{section}.{workload_key} differs from inventory")
    if not workload.get("cases"):
        issues.append("workload has no cases")
    maximum = workload.get("maximum_profile", {})
    words = maximum.get("pinned_output_words", [])
    if (len(words) != 47 or words[0] != 46
            or maximum.get("output_bytes") != 376):
        issues.append("maximum 46-cell profile does not pin 376 bytes")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
