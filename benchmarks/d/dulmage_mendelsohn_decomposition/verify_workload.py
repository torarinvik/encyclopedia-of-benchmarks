"""Static package inventory and oracle-agreement reviewer."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
import types
from pathlib import Path
from typing import Any

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "dulmage_mendelsohn_decomposition"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
REQUIRED_CASES = {
    "single_isolated_left", "single_isolated_right", "single_perfect_edge",
    "left_surplus_alternating_chain", "right_surplus_alternating_chain",
    "free_vertices_on_both_sides", "complete_left_surplus",
    "perfect_alternating_square", "maximum_complete_bipartite", "duplicate_edge",
    "left_endpoint_out_of_range", "right_endpoint_out_of_range",
    "vertex_count_out_of_range", "edge_count_out_of_range", "truncated_edge",
    "trailing_word_at_parseable_bound", "null_input", "null_input_at_parseable_bound",
}


def _load_oracle(name: str) -> Any:
    package_name = "_dulmage_mendelsohn_decomposition_inventory"
    if package_name not in sys.modules:
        package_module = types.ModuleType(package_name)
        package_module.__path__ = [str(PACKAGE)]
        package_module.__package__ = package_name
        sys.modules[package_name] = package_module
    module_name = f"{package_name}.{name}"
    spec = importlib.util.spec_from_file_location(module_name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name}.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def verify(workload: dict[str, Any] | None = None) -> list[str]:
    """Return package issues; an empty list means the inventory agrees."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]
    if workload.get("abi") != "i64_array_scalar":
        issues.append("ABI must be i64_array_scalar")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm and function_symbol must match the export")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_input_length") != 75
            or input_meta.get("maximum_parseable_input_length") != 76
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds do not match the package contract")
    if workload.get("output", {}).get("maximum_result") != 25786580991:
        issues.append("maximum scalar does not match the packed-field ceiling")

    cases = workload.get("cases", [])
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if len(by_id) != len(cases):
        issues.append("fixture IDs must be present and unique")
    if set(by_id) != REQUIRED_CASES:
        issues.append(f"fixture set mismatch: missing={sorted(REQUIRED_CASES - set(by_id))}, "
                      f"extra={sorted(set(by_id) - REQUIRED_CASES)}")
    expected_zero_side_headers = {
        "single_isolated_left": [1, 0],
        "single_isolated_right": [0, 1],
    }
    for case_id, header in expected_zero_side_headers.items():
        if by_id.get(case_id, {}).get("input_values", [])[:2] != header:
            issues.append(f"{case_id}: zero-size side case is missing")
    maximum_case = by_id.get("maximum_complete_bipartite", {})
    maximum_values = maximum_case.get("input_values", [])
    expected_complete_edges = [vertex for left in range(6) for right in range(6)
                               for vertex in (left, right)]
    if (maximum_values[:3] != [6, 6, 36]
            or maximum_case.get("input_length") != 75
            or maximum_values[3:] != expected_complete_edges
            or len(maximum_values) != 75):
        issues.append("maximum_complete_bipartite must be a full K6,6 frame")
    null_bound_case = by_id.get("null_input_at_parseable_bound", {})
    if (null_bound_case.get("input_is_null") is not True
            or null_bound_case.get("input_length") != 76
            or null_bound_case.get("input_values") != []):
        issues.append("null_input_at_parseable_bound must be null with length 76")

    primary = independent = None
    try:
        primary = _load_oracle("primary_oracle")
        independent = _load_oracle("independent_oracle")
    except (ImportError, OSError, SyntaxError) as error:
        issues.append(f"cannot load oracle modules: {error}")
    if primary is not None and independent is not None:
        for case_id, case in by_id.items():
            values = case.get("input_values")
            null_flag = case.get("input_is_null", False)
            length = case.get("input_length")
            if not isinstance(values, list) or type(null_flag) is not bool or type(length) is not int:
                issues.append(f"{case_id}: malformed fixture metadata")
                continue
            if not null_flag and length != len(values):
                issues.append(f"{case_id}: input_length disagrees with input_values")
            for name, oracle in (("primary", primary), ("independent", independent)):
                actual = oracle.expected_result(values, input_is_null=null_flag,
                                                input_length=length)
                if actual != case.get("expected_result"):
                    issues.append(f"{case_id}: {name} result {actual} differs from fixture")

    readme_path = PACKAGE / "README.md"
    if not readme_path.is_file():
        issues.append("missing README.md")
        readme = ""
    else:
        readme = readme_path.read_text(encoding="utf-8")
    for link in (
        "https://github.com/OI-wiki/OI-wiki/blob/master/docs/graph/graph-matching/bigraph-match.md",
        "https://doi.org/10.4153/CJM-1958-052-0",
    ):
        if link not in readme:
            issues.append(f"README omits source link: {link}")
    for relative in ("RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
        if f"]({relative})" not in readme:
            issues.append(f"README omits package link: {relative}")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/d/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "d" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port: {source}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not declare the exported symbol")
        if f"]({relative})" not in readme:
            issues.append(f"README path mismatch for {language}")
    for match in re.finditer(r"\]\(([^)]+)\)", readme):
        target = match.group(1)
        if "://" in target or target.startswith("#"):
            continue
        if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
            issues.append(f"unresolved README target: {target}")
    return issues


if __name__ == "__main__":
    issues = verify()
    for issue in issues:
        print(issue)
    if issues:
        raise SystemExit(1)
