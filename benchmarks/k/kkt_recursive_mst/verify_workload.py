"""Workload/reference validation for the bounded KKT recursive MSF package."""

from __future__ import annotations

from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary


def verify_workload(workload: dict) -> None:
    if (not isinstance(workload, dict)
            or workload.get("algorithm") != "kkt_recursive_mst"
            or workload.get("function_symbol") != "kkt_recursive_mst"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("KKT recursive MST workload identity mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("KKT recursive MST workload has no cases")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("KKT recursive MST workload has an invalid case")
        if case["id"] in seen:
            raise ValueError(f"duplicate KKT recursive MST case: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool
                or is_null and (values or not 0 <= length <= 52)
                or not is_null and (length != len(values) or length > 52)):
            raise ValueError(f"invalid KKT recursive MST framing: {case.get('id')}")
        expected = case.get("expected_result")
        actual_primary = primary(values, is_null, length)
        actual_independent = independent(values, is_null, length)
        if (type(expected) is not int or expected != actual_primary
                or expected != actual_independent):
            raise ValueError(f"KKT recursive MST reference mismatch: {case['id']}")
    required = {
        "single_isolated_vertex", "one_zero_weight_edge", "triangle_unique_weights",
        "triangle_equal_weights_input_id_tie", "disconnected_components",
        "maximum_frame_two_boruvka_cycle_pruning", "maximum_nonnegative_seed",
        "empty_edge_set", "zero_vertices", "negative_seed", "reversed_endpoint_order",
        "duplicate_undirected_edge", "weight_above_bound", "endpoint_out_of_range",
        "edge_count_frame_mismatch", "trailing_word", "null_input", "null_at_parser_limit",
    }
    if not required <= seen:
        raise ValueError("KKT recursive MST workload is missing required cases")
