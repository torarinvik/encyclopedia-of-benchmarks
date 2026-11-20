"""Read-only static checks for the BK-tree package inventory."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/b/bk_tree_edit_distance_search.c",
    "c3": ROOT / "c3/b/bk_tree_edit_distance_search.c3",
    "cpp": ROOT / "cpp/b/bk_tree_edit_distance_search.cpp",
    "elisa": ROOT / "elisa/b/bk_tree_edit_distance_search.elisa",
    "mojo": ROOT / "mojo/b/bk_tree_edit_distance_search.mojo",
    "nim": ROOT / "nim/b/bk_tree_edit_distance_search.nim",
    "odin": ROOT / "odin/b/bk_tree_edit_distance_search.odin",
    "rust": ROOT / "rust/b/bk_tree_edit_distance_search.rs",
    "v": ROOT / "v/b/bk_tree_edit_distance_search.v",
    "zig": ROOT / "zig/b/bk_tree_edit_distance_search.zig",
}
REQUIRED_CASES = {
    "empty-dictionary-empty-batch", "empty-dictionary-queries", "empty-word-exact",
    "zero-radius-exact-and-miss", "radius-one-overlap", "metric-pruning-radius-two",
    "maximum-valid-frame", "maximum-parseable-trailing-word", "invalid-radius",
    "duplicate-dictionary-word", "invalid-active-symbol", "nonzero-unused-symbol",
    "empty-frame", "null-input", "signed-minimum", "signed-maximum",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "__init__.py",
        "verify_workload.py", "check_inventory.py",
    )
    for filename in required:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact {filename}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "bk_tree_edit_distance_search" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the ABI symbol")
        if language == "elisa" and ("view[i64]" not in source or "UnsafePointer" in source):
            issues.append("Elisa should use a bounded input view and avoid UnsafePointer")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package metadata: {error}"]
    expected_paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if (inventory.get("algorithm") != "bk_tree_edit_distance_search"
            or inventory.get("abi") != "i64_array_scalar"
            or set(inventory.get("native_paths", [])) != expected_paths):
        issues.append("inventory identity or ten native paths are incorrect")
    if (workload.get("algorithm") != "bk_tree_edit_distance_search"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != 27
            or workload.get("input", {}).get("maximum_parseable_length") != 28
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("workload differs from the reviewed contract bounds")
    cases = workload.get("cases", [])
    if {case.get("id") for case in cases if isinstance(case, dict)} != REQUIRED_CASES:
        issues.append("workload fixture set differs from the reviewed boundary set")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload includes a non-object fixture")
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool
                or (is_null and length != 0)
                or (not is_null and length != len(values))):
            issues.append(f"invalid framing for {case.get('id')}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
