"""Static contract and fixture review for the bounded Pell profile."""

from __future__ import annotations

import json
from math import isqrt
from pathlib import Path

from .independent_oracle import MAX_Y_SEARCH, expected_result as independent
from .primary_oracle import (
    MAX_D,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MIN_D,
    PACK_MASK,
    PACK_SHIFT,
    WORKSPACE_BYTES,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/p/pell_fundamental_solution"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
SYMBOL = "pell_fundamental_solution"
REQUIRED = {
    "d-two", "d-thirteen", "d-twenty-nine", "d-thirty-one",
    "square-four", "below-domain", "above-domain", "trailing-value",
    "empty-input", "null-input",
}


def _nonsquare(value: int) -> bool:
    root = isqrt(value)
    return root * root != value


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "p" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != "https://oi-wiki.org/math/number-theory/pell-equation/"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[D]"
            or input_spec.get("D_range") != [MIN_D, MAX_D]
            or input_spec.get("D_must_be_nonsquare") is not True
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_result") != -1
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("encoding") != "(x << 32) | y for the least positive solution x^2-D*y^2=1"
            or output_spec.get("invalid_result") != -1
            or workload.get("complexity", {}).get("auxiliary_space") != "O(1)"
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or MAX_Y_SEARCH != 4096
            or PACK_MASK != (1 << PACK_SHIFT) - 1):
        issues.append("workload identity, Pell contract, packed output, or workspace budget differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(is_null) is not bool
                or type(input_length) is not int
                or (is_null and (values or input_length != 0))
                or (not is_null and input_length != len(values))
                or type(expected) is not int):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        primary_result = primary(values, input_is_null=is_null, input_length=input_length)
        independent_result = independent(values, input_is_null=is_null, input_length=input_length)
        if primary_result != expected or independent_result != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")

    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))

    # The narrow source domain lets the independent y-scan cross-check every
    # valid discriminant without requiring compiled ports or generated fixtures.
    for d_value in range(MIN_D, MAX_D + 1):
        result = primary([d_value])
        oracle = independent([d_value])
        if result != oracle:
            issues.append(f"continued-fraction/exhaustive mismatch for D={d_value}")
        if _nonsquare(d_value):
            if result < 0:
                issues.append(f"missing fundamental solution for D={d_value}")
                continue
            x = result >> PACK_SHIFT
            y = result & PACK_MASK
            if (x <= 0 or y <= 0 or x * x - d_value * y * y != 1
                    or x >= 1 << PACK_SHIFT or y >= 1 << PACK_SHIFT):
                issues.append(f"invalid packed Pell pair for D={d_value}")
        elif result != -1:
            issues.append(f"square D should be rejected: D={d_value}")
    return issues


static_issues = verify_workload
