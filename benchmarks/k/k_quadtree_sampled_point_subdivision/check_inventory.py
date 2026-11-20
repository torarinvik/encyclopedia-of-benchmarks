"""Static source/metadata inventory; intentionally not run."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/k/k_quadtree_sampled_point_subdivision.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
}


def static_issues() -> list[str]:
    issues: list[str] = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    if inventory.get("algorithm") != "k_quadtree_sampled_point_subdivision":
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
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload and inventory algorithm IDs differ")
    bounds = (
        ("input", "maximum_valid_length", "maximum_valid_input_words"),
        ("input", "maximum_parseable_length", "maximum_parseable_input_words"),
        ("output", "maximum_output_bytes", "maximum_output_bytes"),
        ("workspace", "bytes", "workspace_bytes"),
    )
    for workload_section, workload_key, inventory_key in bounds:
        if workload[workload_section].get(workload_key) != inventory.get(inventory_key):
            issues.append(f"{workload_section}.{workload_key} differs from inventory")
    maximum_words = workload["maximum_profile"].get("pinned_output_words", [])
    if (len(maximum_words) != 63 or maximum_words[0] != 31
            or workload["maximum_profile"].get("output_bytes") != 504):
        issues.append("maximum 31-split output fixture does not pin 504 bytes")
    if not workload.get("cases"):
        issues.append("workload has no cases")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
