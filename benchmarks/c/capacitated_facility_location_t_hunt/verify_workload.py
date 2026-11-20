"""Static package inventory and fixture/oracle consistency checks."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .independent_oracle import expected_output as independent_expected_output
from .primary_oracle import expected_output as primary_expected_output

PACKAGE_DIR = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE_DIR.parents[2]
LANGUAGES = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "mojo": "mojo",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Return static package, metadata, link, and oracle-fixture problems."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE_DIR / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]
    algorithm = "capacitated_facility_location_t_hunt"
    if (workload.get("algorithm") != algorithm
            or workload.get("function_symbol") != algorithm
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI does not match the package")
    if workload.get("input", {}).get("maximum_valid_length") != 67:
        issues.append("maximum valid input length differs from the bounded frame")
    if workload.get("input", {}).get("maximum_parseable_length") != 68:
        issues.append("maximum parseable input length differs from the bounded frame")
    if workload.get("output", {}).get("maximum_bytes") != 40:
        issues.append("maximum output size differs from the fixed five-word record")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload must contain fixture cases")
        cases = []
    for case in cases:
        label = case.get("id", "<unnamed>")
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        flags = {
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if not isinstance(values, list) or not isinstance(expected_hex, str):
            issues.append(f"{label}: input_values or expected_output_hex is malformed")
            continue
        for reference_name, reference in (
                ("primary", primary_expected_output),
                ("independent", independent_expected_output)):
            try:
                actual_result, actual_bytes = reference(values, capacity=capacity, **flags)
            except (TypeError, ValueError, OverflowError) as error:
                issues.append(f"{label}: {reference_name} oracle rejected fixture shape: {error}")
                continue
            if actual_result != expected_result or actual_bytes.hex() != expected_hex:
                issues.append(f"{label}: {reference_name} oracle differs from pinned expected result")
    readme_path = PACKAGE_DIR / "README.md"
    try:
        readme = readme_path.read_text(encoding="utf-8")
    except OSError as error:
        issues.append(f"cannot read README.md: {error}")
        readme = ""
    for language, extension in LANGUAGES.items():
        relative = f"../../../{language}/c/{algorithm}.{extension}"
        source = REPO_ROOT / language / "c" / f"{algorithm}.{extension}"
        if not source.is_file():
            issues.append(f"missing {language} port: {source}")
        elif algorithm not in source.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not export the expected symbol")
        if f"]({relative})" not in readme:
            issues.append(f"README has no correct relative link for {language}")
    if not (PACKAGE_DIR / "RIGHTS.md").is_file():
        issues.append("missing RIGHTS.md")
    markdown_links = re.findall(r"\]\(([^)]+)\)", readme)
    for target in markdown_links:
        if "://" in target or target.startswith("#"):
            continue
        resolved = (PACKAGE_DIR / target.split("#", 1)[0]).resolve()
        if not resolved.exists():
            issues.append(f"README link target does not exist: {target}")
    return issues
