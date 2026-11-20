"""Static inventory and oracle-agreement review helpers; inert on import."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
import sys
from typing import Any

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "cocomparability_ldfs_minimum_path_cover"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
REQUIRED_CASES = {
    "singleton", "three_vertex_path", "four_vertex_star_two_paths",
    "complete_four", "eight_vertex_star_maximum_case", "disconnected_graph",
    "umbrella_violation", "asymmetric_adjacency", "self_loop_bit",
    "out_of_range_mask_bit", "duplicate_order_vertex", "zero_vertex_count",
    "trailing_word_at_parseable_bound", "null_input",
    "null_input_at_parseable_bound",
}


def _read_workload(workload: dict[str, Any] | None) -> tuple[dict[str, Any] | None, list[str]]:
    if workload is not None:
        return workload, []
    try:
        return json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8")), []
    except (OSError, json.JSONDecodeError) as error:
        return None, [f"cannot read workload.json: {error}"]


def _load_oracle(name: str) -> Any:
    package_text = str(PACKAGE)
    if package_text not in sys.path:
        sys.path.insert(0, package_text)
    spec = importlib.util.spec_from_file_location(f"_cocopath_{name}", PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Return package-file and pinned-metadata issues without evaluating oracles."""
    issues: list[str] = []
    workload, read_issues = _read_workload(workload)
    issues.extend(read_issues)
    if workload is None:
        return issues

    if workload.get("abi") != "i64_array_scalar":
        issues.append("ABI must be i64_array_scalar")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm and function_symbol must match the export")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_input_length") != 17
            or input_meta.get("maximum_parseable_input_length") != 18
            or input_meta.get("vertex_count_range") != [1, 8]
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds do not match the bounded contract")
    if (workload.get("output", {}).get("maximum_result") != 8
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("output or workspace bound does not match the contract")
    try:
        primary = _load_oracle("primary_oracle")
        if (primary.WORKSPACE_BYTES != workload.get("workspace", {}).get("bytes")
                or primary.MAX_VALID_INPUT_LENGTH != input_meta.get("maximum_valid_input_length")
                or primary.MAX_PARSEABLE_INPUT_LENGTH != input_meta.get("maximum_parseable_input_length")
                or primary.MAX_RESULT != workload.get("output", {}).get("maximum_result")):
            issues.append("primary bounds disagree with workload metadata")
    except (ImportError, OSError, SyntaxError, AttributeError) as error:
        issues.append(f"cannot inspect primary workspace constant: {error}")

    cases = workload.get("cases", [])
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(case_ids) != len(cases) or len(set(case_ids)) != len(case_ids):
        issues.append("fixture IDs must be present and unique")
    if set(case_ids) != REQUIRED_CASES:
        issues.append(f"fixture set mismatch: missing={sorted(REQUIRED_CASES - set(case_ids))}, "
                      f"extra={sorted(set(case_ids) - REQUIRED_CASES)}")

    readme_path = PACKAGE / "README.md"
    readme = readme_path.read_text(encoding="utf-8") if readme_path.is_file() else ""
    if not readme_path.is_file():
        issues.append("missing README.md")
    for relative in ("RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
        if f"]({relative})" not in readme:
            issues.append(f"README omits package link: {relative}")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/c/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "c" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port: {source}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not declare the exported symbol")
        if f"]({relative})" not in readme:
            issues.append(f"README path mismatch for {language}: {relative}")
    for match in re.finditer(r"\]\(([^)]+)\)", readme):
        target = match.group(1)
        if "://" in target or target.startswith("#"):
            continue
        if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
            issues.append(f"unresolved README target: {target}")
    return issues


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Check pinned expected values against the two independently shaped references."""
    workload, issues = _read_workload(workload)
    if workload is None:
        return issues
    try:
        primary = _load_oracle("primary_oracle")
        independent = _load_oracle("independent_oracle")
    except (ImportError, OSError, SyntaxError) as error:
        return [*issues, f"cannot load both oracle modules: {error}"]
    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            issues.append("each fixture must be an object")
            continue
        case_id = case.get("id", "<missing-id>")
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be a list")
            continue
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        length = case.get("input_length")
        if type(is_null) is not bool or type(length) is not int:
            issues.append(f"{case_id}: input_is_null and input_length must be typed")
            continue
        if not is_null and length != len(values):
            issues.append(f"{case_id}: input_length disagrees with input_values")
        for name, oracle in (("primary", primary), ("independent", independent)):
            actual = oracle.expected_result(values, input_is_null=is_null,
                                            input_length=length)
            if actual != expected:
                issues.append(f"{case_id}: {name} returned {actual}, expected {expected}")
    return issues
