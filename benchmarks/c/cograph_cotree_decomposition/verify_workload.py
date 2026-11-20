"""Static package inventory and dual-reference fixture reviewer."""

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
SYMBOL = "cograph_cotree_decomposition"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
REQUIRED_CASES = {
    "singleton", "empty_three_vertex_graph", "single_edge", "three_vertex_path",
    "four_cycle_two_level_cotree", "path_three_plus_isolate", "induced_p4_non_cograph",
    "complete_graph_maximum_input", "maximum_cotree_output", "duplicate_unordered_edge",
    "self_loop", "endpoint_out_of_range", "truncated_edge", "trailing_word_at_parseable_bound",
    "null_input_at_parseable_bound", "short_output_capacity", "null_output",
    "invalid_input_precedes_null_output",
}


def _load_oracle(name: str) -> Any:
    package_name = "_cograph_cotree_decomposition_inventory"
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
    """Return inventory issues; this function is intentionally not invoked here."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI must be i64_array_bytes_output")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm and function_symbol must match the export")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_input_length") != 134
            or input_meta.get("maximum_parseable_input_length") != 135
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds do not match the two-word graph frame")
    output_meta = workload.get("output", {})
    if (output_meta.get("maximum_output_bytes") != 47
            or output_meta.get("null_output_result") != -2
            or output_meta.get("insufficient_capacity_result") != -2):
        issues.append("output bounds or error values do not match the cotree profile")

    cases = workload.get("cases", [])
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if len(by_id) != len(cases):
        issues.append("fixture IDs must be present and unique")
    if set(by_id) != REQUIRED_CASES:
        issues.append(f"fixture set mismatch: missing={sorted(REQUIRED_CASES - set(by_id))}, "
                      f"extra={sorted(set(by_id) - REQUIRED_CASES)}")
    maximum = by_id.get("complete_graph_maximum_input", {})
    maximum_values = maximum.get("input_values", [])
    expected_complete_edges = [vertex for u in range(12) for v in range(u + 1, 12)
                               for vertex in (u, v)]
    if (maximum_values != [12, 66, *expected_complete_edges]
            or maximum.get("input_length") != 134):
        issues.append("complete_graph_maximum_input must be the full K12 frame")
    trailing = by_id.get("trailing_word_at_parseable_bound", {})
    if (trailing.get("input_length") != 135 or len(trailing.get("input_values", [])) != 135
            or trailing.get("input_values", [])[:-1] != maximum_values):
        issues.append("trailing_word_at_parseable_bound must append one word to the K12 frame")
    null_bound = by_id.get("null_input_at_parseable_bound", {})
    if (null_bound.get("input_is_null") is not True or null_bound.get("input_length") != 135
            or null_bound.get("input_values") != []):
        issues.append("null_input_at_parseable_bound must have null input and length 135")
    max_output = by_id.get("maximum_cotree_output", {})
    if (max_output.get("expected_result") != 47
            or len(max_output.get("expected_output_hex", "")) != 94):
        issues.append("maximum_cotree_output must exercise the 47-byte output bound")

    try:
        primary = _load_oracle("primary_oracle")
        independent = _load_oracle("independent_oracle")
    except (ImportError, OSError, SyntaxError) as error:
        issues.append(f"cannot load package references: {error}")
        primary = independent = None
    if primary is not None and independent is not None:
        for case_id, case in by_id.items():
            values = case.get("input_values")
            null_flag = case.get("input_is_null", False)
            length = case.get("input_length")
            if not isinstance(values, list) or type(null_flag) is not bool or type(length) is not int:
                issues.append(f"{case_id}: malformed fixture input metadata")
                continue
            if not null_flag and length != len(values):
                issues.append(f"{case_id}: input_length disagrees with input_values")
            reference_bytes: list[bytes | None] = []
            for oracle in (primary, independent):
                reference_bytes.append(oracle.expected_output(
                    values, input_is_null=null_flag, input_length=length))
            if reference_bytes[0] != reference_bytes[1]:
                issues.append(f"{case_id}: primary and independent output bytes differ")
                continue
            result = case.get("expected_result")
            encoded = case.get("expected_output_hex")
            capacity = case.get("output_capacity", primary.MAX_OUTPUT_BYTES)
            output_is_null = case.get("output_is_null", False)
            expected_result, expected_output = primary.expected_abi_output(
                values, capacity, output_is_null, null_flag, length)
            if (not isinstance(result, int) or result != expected_result
                    or encoded != expected_output.hex()):
                issues.append(f"{case_id}: fixture result or bytes disagree with the references")

    readme_path = PACKAGE / "README.md"
    if not readme_path.is_file():
        issues.append("missing README.md")
        readme = ""
    else:
        readme = readme_path.read_text(encoding="utf-8")
    for link in (
        "https://doi.org/10.1016/0166-218X(81)90013-5",
        "https://doi.org/10.1137/0214065",
    ):
        if link not in readme:
            issues.append(f"README omits primary source link: {link}")
    for relative in ("RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py"):
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
