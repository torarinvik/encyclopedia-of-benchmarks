"""Static fixture and contract review for the EIBFS package."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from benchmarks.eibfs_maxflow_oracle import (
        MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES, expected_result as primary_result,
    )
    from benchmarks.eibfs_maxflow_verifier_oracle import expected_result as independent_result
except ImportError:  # Import as a package module from benchmarks/e/eibfs_maxflow.
    from ...eibfs_maxflow_oracle import (
        MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES, expected_result as primary_result,
    )
    from ...eibfs_maxflow_verifier_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    issues: list[str] = []
    try:
        data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if data.get("algorithm") != "eibfs_maxflow":
        issues.append("algorithm ID mismatch")
    if data.get("function_symbol") != "eibfs_maxflow":
        issues.append("function symbol mismatch")
    if data.get("abi") != "i64_array_scalar":
        issues.append("ABI mismatch")
    contract = data.get("input", {})
    if contract.get("vertex_count_range") != [2, MAX_VERTICES]:
        issues.append("vertex bound mismatch")
    if contract.get("edge_count_range") != [0, MAX_EDGES]:
        issues.append("edge bound mismatch")
    if contract.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid length mismatch")
    if contract.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable length mismatch")
    if data.get("workspace", {}).get("bytes") != 8192:
        issues.append("workspace claim mismatch")
    cases = data.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["cases must be a list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("non-object fixture")
            continue
        name = case.get("id", "<unnamed>")
        seen.add(name)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"fixture input is not an array: {name}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable bound: {name}")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        if type(input_is_null) is not bool:
            issues.append(f"fixture null flag is not boolean: {name}")
            continue
        if primary_result(values, input_is_null, input_length) != expected:
            issues.append(f"primary fixture mismatch: {name}")
        if independent_result(values, input_is_null, input_length) != expected:
            issues.append(f"independent fixture mismatch: {name}")
    for required in ("maximum-valid-frame-zero-flow", "maximum-parseable-length",
                     "parallel-arcs", "antiparallel-arcs", "maximum-capacity-parallel-flow",
                     "null-input-zero-length", "null-input-parser-limit"):
        if required not in seen:
            issues.append(f"required fixture missing: {required}")
    for case_id, length in (("null-input-zero-length", 0), ("null-input-parser-limit", 77)):
        case = next((item for item in cases if isinstance(item, dict) and item.get("id") == case_id), None)
        if case is not None and (case.get("input_values") != []
                                 or case.get("input_length") != length
                                 or case.get("input_is_null") is not True
                                 or case.get("expected_result") != -1):
            issues.append(f"null ABI fixture contract mismatch: {case_id}")
    return issues
