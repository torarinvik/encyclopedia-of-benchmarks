"""Static input, fixture, and reference checks for the bounded S-ARD profile."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import expected_result as primary_result
    from .independent_oracle import expected_result as independent_result
except ImportError:
    from primary_oracle import expected_result as primary_result
    from independent_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent


def verify() -> list[str]:
    issues: list[str] = []
    try:
        data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if data.get("algorithm") != "region_discharge_path_push_relabel_maxflow":
        issues.append("algorithm ID mismatch")
    if data.get("function_symbol") != "region_discharge_path_push_relabel_maxflow":
        issues.append("function symbol mismatch")
    if data.get("abi") != "i64_array_scalar":
        issues.append("ABI mismatch")
    contract = data.get("input", {})
    for field, expected in (
        ("vertices_range_including_terminals", [4, 8]),
        ("directed_arc_record_count_range", [1, 12]),
        ("region_count_range", [2, 4]),
        ("capacity_range", [0, 7]),
        ("maximum_valid_input_length", 49),
        ("maximum_parseable_input_length", 50),
        ("maximum_boundary_vertices", 6),
    ):
        if contract.get(field) != expected:
            issues.append(f"contract field mismatch: {field}")
    if data.get("output", {}).get("valid_result_range") != [0, 84]:
        issues.append("result bound mismatch")
    cases = data.get("cases")
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
            issues.append(f"fixture input is not a list: {name}")
            continue
        expected = case.get("expected_result")
        null_flag = case.get("input_is_null", False)
        length = case.get("input_length")
        if type(null_flag) is not bool:
            issues.append(f"null flag is not boolean: {name}")
            continue
        if primary_result(values, null_flag, length) != expected:
            issues.append(f"primary fixture mismatch: {name}")
        if independent_result(values, null_flag, length) != expected:
            issues.append(f"independent fixture mismatch: {name}")
    required = (
        "two-region-chain", "local-path-and-boundary-transfer",
        "direct-terminal-arc-plus-cross-region-route", "antiparallel-cross-capacity",
        "stranded-excess-no-sink-path", "maximum-valid-frame-and-flow",
        "maximum-parseable-length", "null-input", "null-at-parser-limit",
    )
    for name in required:
        if name not in seen:
            issues.append(f"required fixture missing: {name}")
    for case_id, declared_length in (("null-input", 0), ("null-at-parser-limit", 50)):
        case = next((item for item in cases if isinstance(item, dict)
                     and item.get("id") == case_id), None)
        if case is not None and (case.get("input_values") != []
                                 or case.get("input_length") != declared_length
                                 or case.get("input_is_null") is not True
                                 or case.get("expected_result") != -1):
            issues.append(f"null fixture mismatch: {case_id}")
    return issues

