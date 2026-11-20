"""Static workload, dual-reference, and ten-port inventory review."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_N,
    MAX_WEIGHT,
    expected_result as primary,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "general_weighted_matching_primal_dual_blossom"
SOURCE_URL = "https://doi.org/10.1007/978-3-662-21711-5_11"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-isolated-vertex", "triangle-selects-heaviest-edge",
    "weight-objective-beats-cardinality", "unit-five-cycle", "weighted-five-cycle",
    "disconnected-components-add", "sixty-four-vertex-sparse-profile",
    "reversed-duplicate-is-invalid", "self-loop-is-invalid", "zero-weight-is-invalid",
    "weight-over-bound-is-invalid", "truncated-edge-record", "vertex-bound-is-enforced",
    "trailing-input-word-is-invalid", "null-input",
}


def static_issues(workload=None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("N_range") != [1, MAX_N]
            or input_spec.get("weight_range") != [1, MAX_WEIGHT]
            or input_spec.get("maximum_valid_length") != 6050
            or input_spec.get("maximum_parseable_length") != 6051
            or input_spec.get("invalid_input_result") != -2
            or output_spec.get("invalid_input_result") != -2
            or workload.get("workspace", {}).get("bytes") != 524288
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload identity, graph bounds, result convention, or workspace differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != REQUIRED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(is_null) is not bool or type(expected) is not int
                or (is_null and (values or length != 0))):
            issues.append(f"invalid frame or expected result: {case_id}")
            continue
        if primary(values, input_is_null=is_null, input_length=length) != expected:
            issues.append(f"primary fixture mismatch: {case_id}")
        if independent(values, input_is_null=is_null, input_length=length) != expected:
            issues.append(f"independent fixture mismatch: {case_id}")

    for filename in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "check_inventory.py", "INVENTORY.md"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        issues.append("algorithm reference missing from package documentation")
    for language, extension in EXTENSIONS.items():
        relative = f"{language}/g/{SYMBOL}.{extension}"
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing for {language}")
    elisa_path = ROOT / f"elisa/g/{SYMBOL}.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in source or "*i64" in source:
            issues.append("Elisa source should keep array access in safe views")
    return issues


verify_workload = static_issues
