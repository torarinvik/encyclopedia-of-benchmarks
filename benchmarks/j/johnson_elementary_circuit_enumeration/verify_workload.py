"""Static contract, workload, reference, and source-inventory review."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT_UPPER_BOUND,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/j/johnson_elementary_circuit_enumeration"
SYMBOL = "johnson_elementary_circuit_enumeration"
SOURCE_URL = "https://doi.org/10.1137/0204007"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "single-vertex-no-arcs", "one-two-cycle", "one-three-cycle",
    "bidirected-triangle", "two-disjoint-two-cycles",
    "acyclic-branching-graph", "maximum-vertices-and-arcs-dag",
    "maximum-parseable-trailing-value", "trailing-value", "self-loop",
    "duplicate-directed-edge", "endpoint-out-of-range", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "j" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
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
    workspace = workload.get("workspace", {})
    if (workload.get("id") != "johnson-elementary-circuit-enumeration-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("exact_length") != "2+2*m"
            or input_spec.get("n_range") != [1, 8]
            or input_spec.get("edge_count_range") != [0, 24]
            or input_spec.get("vertex_index_range") != "0..n-1"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or input_spec.get("null_input_result") != -1
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("result_range") != "0..16064691498654720"
            or output_spec.get("minimum_valid_result") != 0
            or output_spec.get("maximum_result_upper_bound") != MAX_RESULT_UPPER_BOUND
            or output_spec.get("invalid_result") != -1
            or workspace.get("bytes") != WORKSPACE_BYTES):
        issues.append("workload identity, graph domain, result encoding, or workspace differs")

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
        declared_length = case.get("input_length")
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(declared_length) is not int
                or declared_length != len(values) or type(expected) is not int
                or type(is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if case_id == "maximum-vertices-and-arcs-dag" and (
                len(values) != MAX_VALID_INPUT_LENGTH or values[:2] != [8, 24]
                or expected != 0):
            issues.append("maximum graph fixture differs from the declared valid bound")
        if case_id == "maximum-parseable-trailing-value" and (
                len(values) != MAX_PARSEABLE_INPUT_LENGTH or expected != -1):
            issues.append("maximum parseable fixture differs from the malformed bound")
        primary_result = primary(values, input_is_null=is_null,
                                 input_length=declared_length)
        independent_result = independent(values, input_is_null=is_null,
                                         input_length=declared_length)
        if primary_result != expected or independent_result != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
