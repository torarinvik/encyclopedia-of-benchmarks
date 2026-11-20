"""Static inventory and rights checks; does not execute any native port."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "brace_range_expansion"
PORTS = {
    "c": "c/b/brace_range_expansion.c",
    "c3": "c3/b/brace_range_expansion.c3",
    "cpp": "cpp/b/brace_range_expansion.cpp",
    "elisa": "elisa/b/brace_range_expansion.elisa",
    "mojo": "mojo/b/brace_range_expansion.mojo",
    "nim": "nim/b/brace_range_expansion.nim",
    "odin": "odin/b/brace_range_expansion.odin",
    "rust": "rust/b/brace_range_expansion.rs",
    "v": "v/b/brace_range_expansion.v",
    "zig": "zig/b/brace_range_expansion.zig",
}
PACKAGE_FILES = {
    "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py",
}
FIXTURE_IDS = {
    "simple_integer", "padded_descending_step", "same_case_letter_step",
    "omitted_descending_step", "step_does_not_force_endpoint", "oversized_step",
    "oversized_negative_step",
    "equal_endpoint_positive_step", "equal_endpoint_negative_step",
    "sixteen_padded_items", "maximum_output_short_capacity", "too_many_items",
    "step_points_away_from_endpoint", "mixed_letter_case", "multiple_brace_pairs",
    "short_output", "null_output", "null_input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"export symbol missing from {relative}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())
            or set(inventory.get("package_files", [])) != PACKAGE_FILES):
        issues.append("inventory identity or artifact lists differ")
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_pattern_bytes") != 64
            or bounds.get("maximum_valid_input_length") != 65
            or bounds.get("maximum_parseable_input_length") != 65
            or bounds.get("maximum_items") != 16
            or bounds.get("maximum_prefix_suffix_bytes") != 32
            or bounds.get("maximum_endpoint_digits") != 4
            or bounds.get("step_magnitude_saturation_for_bounded_delta") != 10000
            or bounds.get("maximum_output_word_bytes") != 36
            or bounds.get("maximum_output_bytes") != 591
            or bounds.get("workspace_bytes") != 4096
            or workload.get("input", {}).get("maximum_valid_length") != 65
            or workload.get("input", {}).get("maximum_parseable_length") != 65
            or workload.get("output", {}).get("maximum_bytes") != 591
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("inventory/workload bounds differ from the reserved profile")
    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if (len(ids) != len(cases) or len(ids) != len(set(ids))
            or set(ids) != FIXTURE_IDS or set(ids) != set(inventory.get("fixture_ids", []))):
        issues.append("workload fixture IDs differ from the inventory")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case.get('id')}: input framing differs")
            continue
        try:
            output = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case.get('id')}: malformed expected output hex")
            continue
        result = case.get("expected_result")
        if type(result) is not int:
            issues.append(f"{case.get('id')}: expected result is not an integer")
        elif result < 0 and output:
            issues.append(f"{case.get('id')}: error case must not write")
        elif result >= 0 and (result != len(output) or result > 591):
            issues.append(f"{case.get('id')}: output length differs from result or bound")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in ("CC BY-ND 3.0 US", "GNU FDL 1.3 or later",
                   "No Bash source", "manual prose", "examples, tests, or fixtures were copied"):
        if phrase not in rights:
            issues.append(f"rights/provenance note is missing: {phrase}")
    source_url = "https://www.gnu.org/software/bash/manual/html_node/Brace-Expansion.html"
    if (inventory.get("source", {}).get("url") != source_url
            or source_url not in readme or source_url not in rights):
        issues.append("GNU manual method reference is missing from package provenance")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
