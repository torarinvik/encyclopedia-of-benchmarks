"""Static source inventory and fixture review for the series-link package."""
from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES, expected_output as primary_output,
    )
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES, expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "palindromic_partition_series_links"
SOURCE_URL = "https://www.timothywang.ca/OI-wiki/string/pam/"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "empty-text", "one-symbol", "two-distinct-symbols",
    "whole-text-palindrome", "tie-prefers-longest-final-palindrome",
    "palindrome-prefix-then-singleton", "maximum-text-length",
    "out-of-alphabet-symbol", "trailing-word", "short-output",
    "null-output", "null-input",
}


def static_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    issues: list[str] = []
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("algorithm_contract", {}).get("tie_rule")
                != "For equal minimum piece counts at a prefix, choose the smaller predecessor prefix index."):
        issues.append("identity, provenance, bounds, or pinned contract mismatch")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in rights:
        issues.append("source attribution or clean-room rights note is missing")
    for language, extension in PORTS.items():
        relative = f"../../../{language}/p/{SYMBOL}.{extension}"
        source_path = ROOT / language / "p" / f"{SYMBOL}.{extension}"
        if not source_path.is_file():
            issues.append(f"missing source port: {language}")
        elif SYMBOL not in source_path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing: {language}")
        if f"]({relative})" not in readme:
            issues.append(f"README target missing: {language}")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("http://", "https://", "#")):
            continue
        if not (PACKAGE / target).resolve().is_file():
            issues.append(f"README local target does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture list is missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or capacity < 0
                or type(input_null) is not bool or type(output_null) is not bool
                or input_null and values
                or not input_null and length != len(values)):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case_id}")
            continue
        options = {
            "capacity": capacity,
            "output_is_null": output_null,
            "input_is_null": input_null,
            "input_length": length,
        }
        if (type(expected[0]) is not int
                or primary_output(values, **options) != expected
                or independent_output(values, **options) != expected):
            issues.append(f"reference/fixture disagreement: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def verify_workload(workload: object | None = None) -> int:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    loaded = workload
    if loaded is None:
        loaded = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert isinstance(loaded, dict)
    return len(loaded["cases"])
