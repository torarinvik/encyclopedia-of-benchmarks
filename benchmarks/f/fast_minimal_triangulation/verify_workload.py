"""Static workload/oracle reconciler. This module is supplied but not run."""
from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
                             MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES,
                             expected_output as primary)

PACKAGE = Path(__file__).resolve().parent


def workload_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues: list[str] = []
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    workspace_meta = workload.get("workspace")
    if (workload.get("algorithm") != "fast_minimal_triangulation"
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_meta, dict)
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or not isinstance(workspace_meta, dict)
            or workspace_meta.get("maximum_bytes") != WORKSPACE_BYTES):
        issues.append("workload metadata disagrees with reference bounds")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        name = case["id"]
        if name in seen: issues.append(f"duplicate fixture id: {name}")
        seen.add(name)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        in_null = case.get("input_is_null", False)
        out_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or any(type(x) is not int for x in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or capacity < 0
                or type(in_null) is not bool or type(out_null) is not bool
                or (in_null and values) or (not in_null and length != len(values))):
            issues.append(f"invalid case framing: {name}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected encoding: {name}")
            continue
        args = (values, capacity, out_null, in_null, length)
        if primary(*args) != expected or independent(*args) != expected:
            issues.append(f"reference/fixture disagreement: {name}")
    expected_ids = {
        "single_vertex", "empty_three_vertices", "complete_four", "chordal_path",
        "four_cycle", "five_cycle", "two_triangles_shared_vertex",
        "disconnected_path_components", "maximum_complete_k8_frame", "trailing_word",
        "unsorted_edges", "duplicate_edge", "self_loop", "reversed_edge",
        "null_input", "null_output", "short_output",
    }
    if seen != expected_ids:
        issues.append("fixture inventory mismatch")
    return issues


def verify_workload(workload: object | None = None) -> bool:
    problems = workload_issues(workload)
    if problems:
        raise ValueError("; ".join(problems))
    return True
