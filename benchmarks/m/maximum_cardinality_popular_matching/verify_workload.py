"""Static package inventory and fixture/reference agreement reviewer."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
import sys
import types
from typing import Any

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "maximum_cardinality_popular_matching"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
REQUIRED_CASES = {
    "single_applicant_single_post", "two_applicant_cycle",
    "popular_smaller_than_general_matching", "three_a2_applicants_two_reduced_posts",
    "all_distinct_first_choices", "maximum_valid_frame",
    "ordered_by_preference_not_post_id", "duplicate_post_in_row",
    "empty_preference_list", "post_id_out_of_range", "truncated_preference_rows",
    "applicant_count_out_of_range", "trailing_word_at_parseable_bound",
    "null_input_at_parseable_bound",
}


def _load_oracle(name: str) -> Any:
    package_name = "_maximum_cardinality_popular_matching_inventory"
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
    """Return package issues; this function is intentionally not invoked here."""
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
    if (input_meta.get("maximum_valid_input_length") != 44
            or input_meta.get("maximum_parseable_input_length") != 45
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds do not match the strict-list frame")
    if workload.get("output", {}).get("maximum_result") != 6:
        issues.append("maximum_result must be 6")

    cases = workload.get("cases", [])
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if len(by_id) != len(cases):
        issues.append("fixture IDs must be present and unique")
    if set(by_id) != REQUIRED_CASES:
        issues.append(f"fixture set mismatch: missing={sorted(REQUIRED_CASES - set(by_id))}, "
                      f"extra={sorted(set(by_id) - REQUIRED_CASES)}")
    maximum = by_id.get("maximum_valid_frame", {})
    if (maximum.get("input_length") != 44 or len(maximum.get("input_values", [])) != 44
            or maximum.get("expected_result") != 6):
        issues.append("maximum_valid_frame must exercise the 44-word upper bound")
    trailing = by_id.get("trailing_word_at_parseable_bound", {})
    if (trailing.get("input_length") != 45 or len(trailing.get("input_values", [])) != 45
            or trailing.get("input_values", [])[:-1] != maximum.get("input_values")):
        issues.append("trailing fixture must append one word to the maximum frame")
    null_case = by_id.get("null_input_at_parseable_bound", {})
    if (null_case.get("input_is_null") is not True or null_case.get("input_length") != 45
            or null_case.get("input_values") != []):
        issues.append("null fixture must use the 45-word parseable bound")

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
            if (not isinstance(values, list) or type(null_flag) is not bool
                    or type(length) is not int):
                issues.append(f"{case_id}: malformed input metadata")
                continue
            if not null_flag and length != len(values):
                issues.append(f"{case_id}: input_length disagrees with input_values")
            expected = case.get("expected_result")
            actual_primary = primary.expected_result(values, input_is_null=null_flag,
                                                     input_length=length)
            actual_independent = independent.expected_result(values, input_is_null=null_flag,
                                                              input_length=length)
            if actual_primary != actual_independent:
                issues.append(f"{case_id}: references disagree ({actual_primary} vs {actual_independent})")
            if actual_primary != expected:
                issues.append(f"{case_id}: expected_result {expected} != reference {actual_primary}")

    readme_path = PACKAGE / "README.md"
    if not readme_path.is_file():
        issues.append("missing README.md")
        readme = ""
    else:
        readme = readme_path.read_text(encoding="utf-8")
    for link in ("https://doi.org/10.1137/06067328X",
                 "https://doi.org/10.1007/978-1-4939-2864-4_331"):
        if link not in readme:
            issues.append(f"README omits source link: {link}")
    for relative in ("RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
        if f"]({relative})" not in readme:
            issues.append(f"README omits package link: {relative}")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/m/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "m" / f"{SYMBOL}.{extension}"
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
