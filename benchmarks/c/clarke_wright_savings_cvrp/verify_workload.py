"""Callable static inventory and reference agreement review."""
from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
NAME = "clarke_wright_savings_cvrp"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "empty-customer-set", "negative-saving-keeps-singletons",
    "capacity-allows-one-positive-merge", "endpoint-merges-form-one-route",
    "equal-savings-use-lexicographic-pairs", "zero-saving-is-skipped",
    "maximum-singleton-routes", "capacity-blocks-positive-saving", "asymmetric-distance-matrix",
    "demand-exceeds-capacity", "trailing-word", "insufficient-output-capacity",
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
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("doi") != "10.1287/opre.12.4.568"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != 4096
            or workload.get("algorithm_contract", {}).get("nonpositive_savings")
                != "Zero and negative savings are skipped."):
        issues.append("identity, source, bounds, or pinned algorithm contract mismatch")

    for language, extension in LANGUAGES.items():
        port = REPO_ROOT / language / "c" / f"{NAME}.{extension}"
        if not port.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in port.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")

    if (PACKAGE / "README.md").is_file():
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/c/{NAME}.{extension}"
            if f"]({target})" not in readme:
                issues.append(f"README port target missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"README local target does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
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
        args = (values, capacity, output_null, input_null, length)
        if type(expected[0]) is not int or primary(*args) != expected or independent(*args) != expected:
            issues.append(f"oracle/fixture disagreement: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def verify(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True
