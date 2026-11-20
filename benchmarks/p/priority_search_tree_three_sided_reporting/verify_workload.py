"""Static package inventory and fixture/reference review."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
import types
from pathlib import Path
from typing import Any


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "priority_search_tree_three_sided_reporting"
PORTS = {
    "C": "../../../c/p/priority_search_tree_three_sided_reporting.c",
    "C3": "../../../c3/p/priority_search_tree_three_sided_reporting.c3",
    "C++": "../../../cpp/p/priority_search_tree_three_sided_reporting.cpp",
    "Elisa": "../../../elisa/p/priority_search_tree_three_sided_reporting.elisa",
    "Mojo": "../../../mojo/p/priority_search_tree_three_sided_reporting.mojo",
    "Nim": "../../../nim/p/priority_search_tree_three_sided_reporting.nim",
    "Odin": "../../../odin/p/priority_search_tree_three_sided_reporting.odin",
    "Rust": "../../../rust/p/priority_search_tree_three_sided_reporting.rs",
    "V": "../../../v/p/priority_search_tree_three_sided_reporting.v",
    "Zig": "../../../zig/p/priority_search_tree_three_sided_reporting.zig",
}
REQUIRED_CASES = {
    "empty_points_multiple_queries", "heap_pruning_and_reporting",
    "inclusive_x_and_y_boundaries", "equal_y_priority_ties",
    "maximum_frame_and_packed_result", "duplicate_x_coordinate",
    "duplicate_label", "x_coordinate_out_of_range", "y_coordinate_out_of_range",
    "reversed_query_interval", "truncated_frame",
    "trailing_word_at_parseable_bound", "query_count_out_of_range",
    "null_input", "null_input_at_parseable_bound",
}


def _load_oracles():
    """Load the two Python references as a package, without running a port."""
    package_name = "_pst_static_inventory"
    package = types.ModuleType(package_name)
    package.__path__ = [str(PACKAGE)]  # type: ignore[attr-defined]
    sys.modules[package_name] = package
    loaded = []
    for name in ("primary_oracle", "independent_oracle"):
        module_name = f"{package_name}.{name}"
        path = PACKAGE / f"{name}.py"
        spec = importlib.util.spec_from_file_location(module_name, path)
        if spec is None or spec.loader is None:
            raise ImportError(f"cannot load {path}")
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)
        loaded.append(module)
    return loaded


def verify(workload: dict[str, Any] | None = None) -> list[str]:
    """Return static inventory issues without starting any language toolchain."""
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
        "independent_oracle.py", "verify_workload.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload.json: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be a JSON object"]

    for key, expected in (
        ("algorithm", SYMBOL), ("function_symbol", SYMBOL),
        ("abi", "i64_array_scalar"),
        ("id", "mccreight-radix-priority-search-tree-three-sided-reporting-i64-array-scalar-v1"),
    ):
        if workload.get(key) != expected:
            issues.append(f"workload.{key} must be {expected!r}")
    input_spec = workload.get("input")
    output_spec = workload.get("output")
    if not isinstance(input_spec, dict):
        issues.append("workload.input must be an object")
        input_spec = {}
    if not isinstance(output_spec, dict):
        issues.append("workload.output must be an object")
        output_spec = {}
    for key, expected in (
        ("maximum_valid_length", 47), ("maximum_parseable_length", 48),
        ("maximum_valid_input_length", 47), ("maximum_parseable_input_length", 48),
        ("invalid_input_result", -1),
    ):
        if input_spec.get(key) != expected:
            issues.append(f"workload.input.{key} must be {expected}")
    if output_spec.get("maximum_result") != (1 << 56) - 1:
        issues.append("workload.output.maximum_result must be 2^56-1")
    if workload.get("primary_oracle") != "benchmarks/p/priority_search_tree_three_sided_reporting/primary_oracle.py":
        issues.append("workload.primary_oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/p/priority_search_tree_three_sided_reporting/independent_oracle.py":
        issues.append("workload.independent_oracle path mismatch")

    try:
        primary, independent = _load_oracles()
    except (OSError, ImportError, AttributeError, ValueError) as error:
        return issues + [f"cannot load both Python references: {error}"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload.cases must be a nonempty array"]
    case_ids: set[str] = set()
    for index, case in enumerate(cases):
        label = f"cases[{index}]"
        if not isinstance(case, dict):
            issues.append(f"{label} must be an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id:
            issues.append(f"{label}.id must be a nonempty string")
        elif case_id in case_ids:
            issues.append(f"duplicate fixture id {case_id!r}")
        else:
            case_ids.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int
                or any(type(value) is not int for value in values)):
            issues.append(f"{label} has malformed fixture metadata")
            continue
        if (is_null and (values or length not in (0, 48))
                or not is_null and length != len(values)):
            issues.append(f"{label} has inconsistent null/input length metadata")
        args = {"input_is_null": is_null, "input_length": length}
        if primary.expected_result(values, **args) != expected:
            issues.append(f"{label}.expected_result disagrees with primary reference")
        if independent.expected_result(values, **args) != expected:
            issues.append(f"{label}.expected_result disagrees with independent reference")
    if case_ids != REQUIRED_CASES:
        missing = sorted(REQUIRED_CASES - case_ids)
        extra = sorted(case_ids - REQUIRED_CASES)
        issues.append(f"fixture inventory differs (missing={missing}, extra={extra})")

    maximum_case = next((case for case in cases if isinstance(case, dict)
                         and case.get("id") == "maximum_frame_and_packed_result"), None)
    if (maximum_case is None or maximum_case.get("input_length") != 47
            or maximum_case.get("expected_result") != (1 << 56) - 1):
        issues.append("maximum fixture must exercise 47 words and the 56-bit packed result")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, relative in PORTS.items():
            if f"]({relative})" not in readme:
                issues.append(f"README has no correctly targeted {language} port link")
            target = (PACKAGE / relative).resolve()
            if not target.is_file():
                issues.append(f"missing {language} port: {relative}")
            elif SYMBOL not in target.read_text(encoding="utf-8"):
                issues.append(f"{language} port does not expose {SYMBOL}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("https://", "http://", "mailto:", "#")):
                continue
            local = target.split("#", 1)[0]
            if local and not (PACKAGE / local).resolve().exists():
                issues.append(f"README has unresolved local link {target!r}")
        for phrase in ("three-sided", "strictly smaller", "heap-pruned", "McCreight"):
            if phrase not in readme:
                issues.append(f"README is missing method statement {phrase!r}")

    source = workload.get("source")
    if (not isinstance(source, dict) or source.get("doi") != "10.1137/0214021"
            or source.get("url") != "https://doi.org/10.1137/0214021"):
        issues.append("workload.source must identify McCreight DOI 10.1137/0214021")
    return issues


static_issues = verify
verify_workload = verify
