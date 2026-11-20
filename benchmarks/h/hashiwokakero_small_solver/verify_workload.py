"""Reconcile bounded fixtures with both Python references; never loads native code."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "hashiwokakero_small_solver"
REQUIRED_CASES = {
    "two-islands-double-bridge",
    "two-islands-single-bridge",
    "shared-endpoint-chain",
    "lexicographic-tie-square",
    "maximum-edge-count-2x3",
    "disconnected-degree-satisfied",
    "interior-crossing-required",
    "valid-but-degree-unsatisfiable",
    "maximum-length-no-visible-bridges",
    "duplicate-coordinate",
    "coordinate-out-of-range",
    "zero-demand",
    "one-island-out-of-range",
    "trailing-word",
    "null-input",
}


def _load_reference(filename: str):
    path = PACKAGE / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load reference source: {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues(workload=None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return ["workload root must be an object"]
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    algorithm = workload.get("algorithm")
    if (algorithm != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or input_meta.get("maximum_valid_length") != 19
            or input_meta.get("maximum_parseable_length") != 20
            or workload.get("contract", {}).get("island_count_range") != [2, 6]
            or workload.get("contract", {}).get("coordinate_range") != [0, 7]
            or workload.get("contract", {}).get("demand_range") != [1, 8]
            or workload.get("method", {}).get("maximum_candidate_edges") != 7
            or output_meta.get("valid_unsatisfiable_result") != -2
            or output_meta.get("valid_success_range") != [4294967296, 4294978218]):
        issues.append("workload identity, contract, or bounds differ")
    try:
        primary = _load_reference("primary_oracle.py")
        independent = _load_reference("independent_oracle.py")
    except (ImportError, OSError, ValueError) as error:
        return issues + [f"cannot load reference source: {error}"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed workload case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(expected) is not int or type(is_null) is not bool
                or (not is_null and length != len(values))
                or length > 20
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)):
            issues.append(f"invalid scalar fixture framing: {case_id}")
            continue
        actual_primary = primary.expected_result(values, input_is_null=is_null,
                                                 input_length=length)
        actual_independent = independent.expected_result(values, input_is_null=is_null,
                                                         input_length=length)
        if actual_primary != actual_independent:
            issues.append(f"references disagree for {case_id}")
        if actual_primary != expected:
            issues.append(f"pinned fixture differs from references: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


def verify_workload() -> None:
    problems = workload_issues()
    if problems:
        raise ValueError("\n".join(problems))
