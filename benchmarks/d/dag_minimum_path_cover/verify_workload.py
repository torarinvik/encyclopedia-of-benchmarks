"""Static package inventory and oracle-agreement reviewer.

Calling ``verify`` inspects package metadata and evaluates fixture values
against both Python references. This module is intentionally inert on import.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
from typing import Any

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "dag_minimum_path_cover"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
REQUIRED_CASES = {
    "single_vertex", "three_isolated_vertices", "directed_chain",
    "two_disjoint_arcs", "diamond_canonical_tie", "shared_right_conflict",
    "non_numeric_topological_order", "maximum_complete_dag", "duplicate_arc",
    "self_loop", "directed_cycle", "edge_endpoint_out_of_range",
    "edge_count_out_of_range", "truncated_edge_record",
    "trailing_word_at_parseable_bound", "null_input",
    "null_input_at_parseable_bound",
}


def _load_oracle(name: str) -> Any:
    package_path = str(PACKAGE)
    if package_path not in sys.path:
        sys.path.insert(0, package_path)
    spec = importlib.util.spec_from_file_location(f"_dmpc_{name}", PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify(workload: dict[str, Any] | None = None) -> list[str]:
    """Return package issues; an empty list means the static inventory agrees."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]

    if workload.get("abi") != "i64_array_scalar":
        issues.append("ABI must be i64_array_scalar")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload algorithm and function_symbol must match the export")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_input_length") != 92
            or input_meta.get("maximum_parseable_input_length") != 93
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds or invalid result do not match the bounded contract")
    if workload.get("output", {}).get("maximum_result") != 12094627905535:
        issues.append("output maximum does not match the packed i64 contract")

    cases = workload.get("cases", [])
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if len(by_id) != len(cases):
        issues.append("fixture IDs must be present and unique")
    if set(by_id) != REQUIRED_CASES:
        issues.append(f"fixture set mismatch: missing={sorted(REQUIRED_CASES - set(by_id))}, "
                      f"extra={sorted(set(by_id) - REQUIRED_CASES)}")

    primary = independent = None
    try:
        primary = _load_oracle("primary_oracle")
        independent = _load_oracle("independent_oracle")
    except (ImportError, OSError, SyntaxError) as error:
        issues.append(f"cannot load both oracle modules: {error}")

    if primary is not None and independent is not None:
        for case_id, case in by_id.items():
            values = case.get("input_values")
            is_null = case.get("input_is_null", False)
            length = case.get("input_length")
            if not isinstance(values, list):
                issues.append(f"{case_id}: input_values must be an array")
                continue
            if type(is_null) is not bool or type(length) is not int:
                issues.append(f"{case_id}: null flag and input_length must be typed")
                continue
            if not is_null and length != len(values):
                issues.append(f"{case_id}: input_length disagrees with input_values")
            declared = case.get("expected_result")
            for oracle_name, oracle in (("primary", primary), ("independent", independent)):
                actual = oracle.expected_result(values, input_is_null=is_null,
                                                input_length=length)
                if actual != declared:
                    issues.append(f"{case_id}: {oracle_name} returned {actual}, expected {declared}")

    readme_path = PACKAGE / "README.md"
    if not readme_path.is_file():
        issues.append("missing README.md")
        readme = ""
    else:
        readme = readme_path.read_text(encoding="utf-8")
    expected_source_links = (
        "https://oi-wiki.org/graph/graph-matching/bigraph-match/",
        "https://doi.org/10.1090/S0002-9939-1956-0078334-6",
    )
    for link in expected_source_links:
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
            issues.append(f"README path mismatch for {language}: {relative}")

    for match in __import__("re").finditer(r"\]\(([^)]+)\)", readme):
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
