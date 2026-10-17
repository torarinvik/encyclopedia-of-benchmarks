#!/usr/bin/env python3
"""Record a byte-output benchmark over a signed 32-bit input array."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess
import sys

from build_abi import ROOT, sha256_file
from salsa_oracle import I32_MAX, I32_MIN
from salsa_oracle import MAX_OUTPUT_BYTES as SALSA_MAX_OUTPUT_BYTES
from salsa_oracle import MAX_PARSEABLE_INPUT_LENGTH as SALSA_MAX_PARSEABLE_INPUT_LENGTH
from salsa_oracle import expected_output as salsa_expected_output
from steinhaus_johnson_trotter_oracle import MAX_OUTPUT_BYTES as SJT_MAX_OUTPUT_BYTES
from steinhaus_johnson_trotter_oracle import MAX_PARSEABLE_INPUT_LENGTH as SJT_MAX_PARSEABLE_INPUT_LENGTH
from steinhaus_johnson_trotter_oracle import expected_output as sjt_expected_output
from minimum_spanning_tree_kruskal2_oracle import I32_MAX as KRUSKAL2_I32_MAX
from minimum_spanning_tree_kruskal2_oracle import I32_MIN as KRUSKAL2_I32_MIN
from minimum_spanning_tree_kruskal2_oracle import INVALID_RESULT as KRUSKAL2_INVALID_RESULT
from minimum_spanning_tree_kruskal2_oracle import MAX_EDGE_COUNT as KRUSKAL2_MAX_EDGE_COUNT
from minimum_spanning_tree_kruskal2_oracle import MAX_INPUT_LENGTH as KRUSKAL2_MAX_INPUT_LENGTH
from minimum_spanning_tree_kruskal2_oracle import MAX_OUTPUT_BYTES as KRUSKAL2_MAX_OUTPUT_BYTES
from minimum_spanning_tree_kruskal2_oracle import MAX_VERTEX_COUNT as KRUSKAL2_MAX_VERTEX_COUNT
from minimum_spanning_tree_kruskal2_oracle import MIN_VERTEX_COUNT as KRUSKAL2_MIN_VERTEX_COUNT
from minimum_spanning_tree_kruskal2_oracle import OUTPUT_ERROR as KRUSKAL2_OUTPUT_ERROR
from minimum_spanning_tree_kruskal2_oracle import expected_output as kruskal2_expected_output
from scan_scheduling_oracle import I32_MAX as SCAN_I32_MAX
from scan_scheduling_oracle import I32_MIN as SCAN_I32_MIN
from scan_scheduling_oracle import INVALID_RESULT as SCAN_INVALID_RESULT
from scan_scheduling_oracle import MAX_DISK_SIZE as SCAN_MAX_DISK_SIZE
from scan_scheduling_oracle import MAX_INPUT_LENGTH as SCAN_MAX_INPUT_LENGTH
from scan_scheduling_oracle import MAX_OUTPUT_BYTES as SCAN_MAX_OUTPUT_BYTES
from scan_scheduling_oracle import MAX_REQUEST_COUNT as SCAN_MAX_REQUEST_COUNT
from scan_scheduling_oracle import MIN_DISK_SIZE as SCAN_MIN_DISK_SIZE
from scan_scheduling_oracle import OUTPUT_ERROR as SCAN_OUTPUT_ERROR
from scan_scheduling_oracle import expected_output as scan_scheduling_expected_output
from multi_level_feedback_queue_oracle import I32_MAX as MLFQ_I32_MAX
from multi_level_feedback_queue_oracle import I32_MIN as MLFQ_I32_MIN
from multi_level_feedback_queue_oracle import INVALID_RESULT as MLFQ_INVALID_RESULT
from multi_level_feedback_queue_oracle import MAX_BURST_TIME as MLFQ_MAX_BURST_TIME
from multi_level_feedback_queue_oracle import MAX_INPUT_LENGTH as MLFQ_MAX_INPUT_LENGTH
from multi_level_feedback_queue_oracle import MAX_OUTPUT_BYTES as MLFQ_MAX_OUTPUT_BYTES
from multi_level_feedback_queue_oracle import MAX_PROCESS_COUNT as MLFQ_MAX_PROCESS_COUNT
from multi_level_feedback_queue_oracle import MAX_QUEUE_COUNT as MLFQ_MAX_QUEUE_COUNT
from multi_level_feedback_queue_oracle import MAX_TIME_SLICE as MLFQ_MAX_TIME_SLICE
from multi_level_feedback_queue_oracle import OUTPUT_ERROR as MLFQ_OUTPUT_ERROR
from multi_level_feedback_queue_oracle import expected_output as mlfq_expected_output
from preemptive_priority_scheduling_oracle import I32_MAX as PREEMPTIVE_I32_MAX
from preemptive_priority_scheduling_oracle import I32_MIN as PREEMPTIVE_I32_MIN
from preemptive_priority_scheduling_oracle import INVALID_RESULT as PREEMPTIVE_INVALID_RESULT
from preemptive_priority_scheduling_oracle import MAX_ARRIVAL_TIME as PREEMPTIVE_MAX_ARRIVAL_TIME
from preemptive_priority_scheduling_oracle import MAX_BURST_TIME as PREEMPTIVE_MAX_BURST_TIME
from preemptive_priority_scheduling_oracle import MAX_INPUT_LENGTH as PREEMPTIVE_MAX_INPUT_LENGTH
from preemptive_priority_scheduling_oracle import MAX_OUTPUT_BYTES as PREEMPTIVE_MAX_OUTPUT_BYTES
from preemptive_priority_scheduling_oracle import MAX_PROCESS_COUNT as PREEMPTIVE_MAX_PROCESS_COUNT
from preemptive_priority_scheduling_oracle import MAX_PROCESS_ID as PREEMPTIVE_MAX_PROCESS_ID
from preemptive_priority_scheduling_oracle import OUTPUT_ERROR as PREEMPTIVE_OUTPUT_ERROR
from preemptive_priority_scheduling_oracle import expected_output as preemptive_expected_output
from multikey_quick_sort_oracle import I32_MAX as MULTIKEY_I32_MAX
from multikey_quick_sort_oracle import I32_MIN as MULTIKEY_I32_MIN
from multikey_quick_sort_oracle import INVALID_RESULT as MULTIKEY_INVALID_RESULT
from multikey_quick_sort_oracle import MAX_BYTE as MULTIKEY_MAX_BYTE
from multikey_quick_sort_oracle import MAX_INPUT_WORDS as MULTIKEY_MAX_VALID_INPUT_LENGTH
from multikey_quick_sort_oracle import MAX_OUTPUT_BYTES as MULTIKEY_MAX_OUTPUT_BYTES
from multikey_quick_sort_oracle import MAX_PARSEABLE_INPUT_WORDS as MULTIKEY_MAX_INPUT_LENGTH
from multikey_quick_sort_oracle import MAX_STRING_COUNT as MULTIKEY_MAX_STRING_COUNT
from multikey_quick_sort_oracle import MAX_STRING_LENGTH as MULTIKEY_MAX_STRING_LENGTH
from multikey_quick_sort_oracle import MIN_BYTE as MULTIKEY_MIN_BYTE
from multikey_quick_sort_oracle import OUTPUT_ERROR as MULTIKEY_OUTPUT_ERROR
from multikey_quick_sort_oracle import expected_output as multikey_expected_output
from max_pooling_oracle import I32_MAX as MAX_POOLING_I32_MAX
from max_pooling_oracle import I32_MIN as MAX_POOLING_I32_MIN
from max_pooling_oracle import INVALID_RESULT as MAX_POOLING_INVALID_RESULT
from max_pooling_oracle import MAX_INPUT_WORDS as MAX_POOLING_MAX_VALID_INPUT_LENGTH
from max_pooling_oracle import MAX_MATRIX_SIZE as MAX_POOLING_MAX_MATRIX_SIZE
from max_pooling_oracle import MAX_OUTPUT_BYTES as MAX_POOLING_MAX_OUTPUT_BYTES
from max_pooling_oracle import MAX_PARSEABLE_INPUT_WORDS as MAX_POOLING_MAX_INPUT_LENGTH
from max_pooling_oracle import MAX_PIXEL as MAX_POOLING_MAX_PIXEL
from max_pooling_oracle import MAX_STRIDE as MAX_POOLING_MAX_STRIDE
from max_pooling_oracle import MIN_MATRIX_SIZE as MAX_POOLING_MIN_MATRIX_SIZE
from max_pooling_oracle import MIN_PIXEL as MAX_POOLING_MIN_PIXEL
from max_pooling_oracle import MIN_POOL_SIZE as MAX_POOLING_MIN_POOL_SIZE
from max_pooling_oracle import MIN_STRIDE as MAX_POOLING_MIN_STRIDE
from max_pooling_oracle import OUTPUT_ERROR as MAX_POOLING_OUTPUT_ERROR
from max_pooling_oracle import expected_output as max_pooling_expected_output
from rat_maze_oracle import I32_MAX as RAT_MAZE_I32_MAX
from rat_maze_oracle import I32_MIN as RAT_MAZE_I32_MIN
from rat_maze_oracle import INVALID_RESULT as RAT_MAZE_INVALID_RESULT
from rat_maze_oracle import MAX_INPUT_WORDS as RAT_MAZE_MAX_VALID_INPUT_LENGTH
from rat_maze_oracle import MAX_OUTPUT_BYTES as RAT_MAZE_MAX_OUTPUT_BYTES
from rat_maze_oracle import MAX_PARSEABLE_INPUT_WORDS as RAT_MAZE_MAX_INPUT_LENGTH
from rat_maze_oracle import MAX_SIZE as RAT_MAZE_MAX_SIZE
from rat_maze_oracle import MIN_SIZE as RAT_MAZE_MIN_SIZE
from rat_maze_oracle import OUTPUT_ERROR as RAT_MAZE_OUTPUT_ERROR
from rat_maze_oracle import expected_output as rat_maze_expected_output
from minimum_spanning_tree_prims_oracle import I32_MAX as PRIMS_I32_MAX
from minimum_spanning_tree_prims_oracle import I32_MIN as PRIMS_I32_MIN
from minimum_spanning_tree_prims_oracle import INVALID_RESULT as PRIMS_INVALID_RESULT
from minimum_spanning_tree_prims_oracle import MAX_EDGE_COUNT as PRIMS_MAX_EDGE_COUNT
from minimum_spanning_tree_prims_oracle import MAX_INPUT_LENGTH as PRIMS_MAX_INPUT_LENGTH
from minimum_spanning_tree_prims_oracle import MAX_OUTPUT_BYTES as PRIMS_MAX_OUTPUT_BYTES
from minimum_spanning_tree_prims_oracle import MAX_PARSEABLE_INPUT_LENGTH as PRIMS_MAX_PARSEABLE_INPUT_LENGTH
from minimum_spanning_tree_prims_oracle import MAX_VERTEX_COUNT as PRIMS_MAX_VERTEX_COUNT
from minimum_spanning_tree_prims_oracle import MIN_VERTEX_COUNT as PRIMS_MIN_VERTEX_COUNT
from minimum_spanning_tree_prims_oracle import OUTPUT_ERROR as PRIMS_OUTPUT_ERROR
from minimum_spanning_tree_prims_oracle import SOURCE_HEAP_SENTINEL as PRIMS_SOURCE_HEAP_SENTINEL
from minimum_spanning_tree_prims_oracle import expected_output as prims_expected_output
from mo_oracle import I32_MAX as MO_I32_MAX
from mo_oracle import I32_MIN as MO_I32_MIN
from mo_oracle import INVALID_RESULT as MO_INVALID_RESULT
from mo_oracle import MAX_ARRAY_SIZE as MO_MAX_ARRAY_SIZE
from mo_oracle import MAX_INPUT_WORDS as MO_MAX_VALID_INPUT_LENGTH
from mo_oracle import MAX_OUTPUT_BYTES as MO_MAX_OUTPUT_BYTES
from mo_oracle import MAX_PARSEABLE_INPUT_WORDS as MO_MAX_INPUT_LENGTH
from mo_oracle import MAX_QUERY_COUNT as MO_MAX_QUERY_COUNT
from mo_oracle import MAX_VALUE as MO_MAX_VALUE
from mo_oracle import MIN_ARRAY_SIZE as MO_MIN_ARRAY_SIZE
from mo_oracle import MIN_QUERY_COUNT as MO_MIN_QUERY_COUNT
from mo_oracle import MIN_VALUE as MO_MIN_VALUE
from mo_oracle import OUTPUT_ERROR as MO_OUTPUT_ERROR
from mo_oracle import expected_output as mo_expected_output
from hungarian_algorithm_oracle import I32_MAX as HUNGARIAN_I32_MAX
from hungarian_algorithm_oracle import I32_MIN as HUNGARIAN_I32_MIN
from hungarian_algorithm_oracle import INVALID_RESULT as HUNGARIAN_INVALID_RESULT
from hungarian_algorithm_oracle import MAX_COST as HUNGARIAN_MAX_COST
from hungarian_algorithm_oracle import MAX_DIMENSION as HUNGARIAN_MAX_DIMENSION
from hungarian_algorithm_oracle import MAX_OUTPUT_BYTES as HUNGARIAN_MAX_OUTPUT_BYTES
from hungarian_algorithm_oracle import MAX_PARSEABLE_INPUT_WORDS as HUNGARIAN_MAX_INPUT_LENGTH
from hungarian_algorithm_oracle import MAX_VALID_INPUT_WORDS as HUNGARIAN_MAX_VALID_INPUT_LENGTH
from hungarian_algorithm_oracle import MIN_COST as HUNGARIAN_MIN_COST
from hungarian_algorithm_oracle import MIN_DIMENSION as HUNGARIAN_MIN_DIMENSION
from hungarian_algorithm_oracle import OUTPUT_ERROR as HUNGARIAN_OUTPUT_ERROR
from hungarian_algorithm_oracle import expected_output as hungarian_expected_output

MAX_OUTPUT_CAPACITY = 400004
ALGORITHMS = ("salsa", "steinhaus_johnson_trotter", "minimum_spanning_tree_kruskal2",
              "scan_scheduling", "multi_level_feedback_queue", "rat_maze",
              "minimum_spanning_tree_prims",
              "mo",
              "preemptive_priority_scheduling", "multikey_quick_sort", "max_pooling",
              "hungarian_algorithm")


def oracle_for(values: list[int], algorithm: str, output_capacity: int,
               output_is_null: bool, input_is_null: bool,
               input_length: int | None = None) -> tuple[int, bytes]:
    if algorithm == "salsa":
        return salsa_expected_output(values, output_capacity, output_is_null, input_is_null)
    if algorithm == "steinhaus_johnson_trotter":
        return sjt_expected_output(values, output_capacity, output_is_null, input_is_null)
    if algorithm == "minimum_spanning_tree_kruskal2":
        return kruskal2_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "scan_scheduling":
        return scan_scheduling_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "multi_level_feedback_queue":
        return mlfq_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "preemptive_priority_scheduling":
        return preemptive_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "multikey_quick_sort":
        return multikey_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "max_pooling":
        return max_pooling_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "rat_maze":
        return rat_maze_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "minimum_spanning_tree_prims":
        return prims_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "mo":
        return mo_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    if algorithm == "hungarian_algorithm":
        return hungarian_expected_output(
            values, output_capacity, output_is_null, input_is_null, input_length)
    raise ValueError(f"no i32 byte-output oracle for {algorithm}")


def max_parseable_input_length(algorithm: str) -> int:
    if algorithm == "salsa":
        return SALSA_MAX_PARSEABLE_INPUT_LENGTH
    if algorithm == "steinhaus_johnson_trotter":
        return SJT_MAX_PARSEABLE_INPUT_LENGTH
    if algorithm == "minimum_spanning_tree_kruskal2":
        return KRUSKAL2_MAX_INPUT_LENGTH
    if algorithm == "scan_scheduling":
        return SCAN_MAX_INPUT_LENGTH
    if algorithm == "multi_level_feedback_queue":
        return MLFQ_MAX_INPUT_LENGTH
    if algorithm == "preemptive_priority_scheduling":
        return PREEMPTIVE_MAX_INPUT_LENGTH
    if algorithm == "multikey_quick_sort":
        return MULTIKEY_MAX_INPUT_LENGTH
    if algorithm == "max_pooling":
        return MAX_POOLING_MAX_INPUT_LENGTH
    if algorithm == "rat_maze":
        return RAT_MAZE_MAX_INPUT_LENGTH
    if algorithm == "minimum_spanning_tree_prims":
        return PRIMS_MAX_PARSEABLE_INPUT_LENGTH
    if algorithm == "mo":
        return MO_MAX_INPUT_LENGTH
    if algorithm == "hungarian_algorithm":
        return HUNGARIAN_MAX_INPUT_LENGTH
    raise ValueError(f"no i32 byte-output input bound for {algorithm}")


def max_output_bytes(algorithm: str) -> int:
    if algorithm == "salsa":
        return SALSA_MAX_OUTPUT_BYTES
    if algorithm == "steinhaus_johnson_trotter":
        return SJT_MAX_OUTPUT_BYTES
    if algorithm == "minimum_spanning_tree_kruskal2":
        return KRUSKAL2_MAX_OUTPUT_BYTES
    if algorithm == "scan_scheduling":
        return SCAN_MAX_OUTPUT_BYTES
    if algorithm == "multi_level_feedback_queue":
        return MLFQ_MAX_OUTPUT_BYTES
    if algorithm == "preemptive_priority_scheduling":
        return PREEMPTIVE_MAX_OUTPUT_BYTES
    if algorithm == "multikey_quick_sort":
        return MULTIKEY_MAX_OUTPUT_BYTES
    if algorithm == "max_pooling":
        return MAX_POOLING_MAX_OUTPUT_BYTES
    if algorithm == "rat_maze":
        return RAT_MAZE_MAX_OUTPUT_BYTES
    if algorithm == "minimum_spanning_tree_prims":
        return PRIMS_MAX_OUTPUT_BYTES
    if algorithm == "mo":
        return MO_MAX_OUTPUT_BYTES
    if algorithm == "hungarian_algorithm":
        return HUNGARIAN_MAX_OUTPUT_BYTES
    raise ValueError(f"no i32 byte-output size bound for {algorithm}")


KRUSKAL2_CASE_IDS = frozenset({
    "single_vertex_empty_graph", "two_vertex_single_edge", "triangle_distinct_weights",
    "stable_tie_source_node_neighbor_order", "stable_tie_input_order_within_node",
    "negative_weight_mst", "signed_i32_weight_edges", "maximum_input_and_output_64_edges",
    "disconnected_two_vertices", "disconnected_three_vertices", "vertex_count_zero",
    "vertex_count_above_bound", "negative_edge_count", "edge_count_above_bound",
    "truncated_edge_record", "trailing_edge_record", "self_edge", "reversed_endpoint_order",
    "endpoint_out_of_range", "duplicate_edge", "input_length_mismatch",
    "null_input_positive_length", "null_output_single_vertex", "short_output_single_vertex",
    "exact_output_single_vertex", "null_output_connected_graph", "short_output_connected_graph",
    "exact_output_connected_graph", "invalid_graph_precedes_null_output", "one_vertex_rejects_edges",
})


def validate_kruskal2_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "graphs/minimum_spanning_tree_kruskal2.py",
        "symbol": "GraphUndirectedWeighted.kruskal",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_kruskal2.py",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[vertex_count, edge_count, (u, v, weight)...]",
        "vertex_count_range": [KRUSKAL2_MIN_VERTEX_COUNT, KRUSKAL2_MAX_VERTEX_COUNT],
        "edge_count_range": [0, KRUSKAL2_MAX_EDGE_COUNT],
        "weight_range": [KRUSKAL2_I32_MIN, KRUSKAL2_I32_MAX],
        "endpoint_rule": "Each edge uses canonical endpoints 0 <= u < v < vertex_count.",
        "edge_uniqueness": "Each undirected edge appears at most once.",
        "connectedness": "The graph must be connected when vertex_count > 1; vertex_count=1 requires edge_count=0.",
        "maximum_valid_input_length": KRUSKAL2_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": KRUSKAL2_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 2 + 3 * edge_count signed-i32 words.",
        "invalid_input_result": KRUSKAL2_INVALID_RESULT,
        "null_input_result": KRUSKAL2_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "[edge_count, (u, v, weight)...] in Kruskal accepted-edge order.",
        "edge_count_for_connected_graph": "vertex_count - 1",
        "single_vertex_output": [0],
        "valid_output_bytes_range": [4, KRUSKAL2_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": KRUSKAL2_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": KRUSKAL2_INVALID_RESULT,
        "null_output_result": KRUSKAL2_OUTPUT_ERROR,
        "insufficient_output_capacity_result": KRUSKAL2_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Invalid or disconnected input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-minimum-spanning-tree-kruskal2-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "minimum_spanning_tree_kruskal2"
            or workload.get("function_symbol") != "minimum_spanning_tree_kruskal2"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": KRUSKAL2_MAX_OUTPUT_BYTES,
                "meaning": "One count word and up to 15 accepted edge triplets.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or KRUSKAL2_MIN_VERTEX_COUNT != 1 or KRUSKAL2_MAX_VERTEX_COUNT != 16
            or KRUSKAL2_MAX_EDGE_COUNT != 64 or KRUSKAL2_MAX_INPUT_LENGTH != 194
            or KRUSKAL2_MAX_OUTPUT_BYTES != 184
            or KRUSKAL2_INVALID_RESULT != -1 or KRUSKAL2_OUTPUT_ERROR != -2
            or len(case_ids) != len(KRUSKAL2_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != KRUSKAL2_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 2
            or null_input_cases[0].get("expected_result") != KRUSKAL2_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_single_vertex": KRUSKAL2_OUTPUT_ERROR,
                "null_output_connected_graph": KRUSKAL2_OUTPUT_ERROR,
                "invalid_graph_precedes_null_output": KRUSKAL2_INVALID_RESULT,
            }):
        raise ValueError("minimum_spanning_tree_kruskal2 workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "minimum_spanning_tree_kruskal2" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "stable ascending sort by weight" not in readme
            or "disconnected" not in readme):
        raise ValueError("minimum_spanning_tree_kruskal2 README is missing its pinned source or semantics")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not KRUSKAL2_I32_MIN <= value <= KRUSKAL2_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= KRUSKAL2_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= KRUSKAL2_MAX_OUTPUT_BYTES):
            raise ValueError(f"minimum_spanning_tree_kruskal2 workload framing is invalid: {case.get('id')}")
        result, output = kruskal2_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"minimum_spanning_tree_kruskal2 workload mismatch: {case.get('id')}")
    length_mismatch = next(case for case in workload["cases"]
                           if case.get("id") == "input_length_mismatch")
    if (len(length_mismatch["input_values"]) == length_mismatch["input_length"]
            or length_mismatch["expected_result"] != KRUSKAL2_INVALID_RESULT):
        raise ValueError("minimum_spanning_tree_kruskal2 is missing its input-length mismatch fixture")


SCAN_CASE_IDS = frozenset({
    "empty_up", "empty_down_zero_capacity", "up_order_endpoint_and_duplicates",
    "down_order_endpoint_and_duplicates", "up_only_right_endpoint_duplicate",
    "down_only_right_endpoint", "up_only_left", "down_only_left_endpoint_duplicate",
    "equal_head_is_right_up", "equal_head_is_right_down", "duplicate_requests_preserved",
    "single_position_up", "single_position_down", "upper_endpoint_at_max_disk",
    "maximum_output_65_values", "disk_size_zero", "disk_size_above_bound",
    "head_below_disk", "head_at_exclusive_upper_bound", "direction_negative",
    "direction_above_bound", "negative_request_count", "request_count_above_bound",
    "truncated_request_list", "trailing_request_word", "request_below_disk",
    "request_at_exclusive_upper_bound", "input_length_mismatch", "null_input_positive_length",
    "null_output_nonempty", "short_output_nonempty", "exact_output_nonempty",
    "null_output_empty", "empty_zero_capacity", "invalid_input_precedes_null_output",
})


def validate_scan_scheduling_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Java",
        "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
        "path": "src/main/java/com/thealgorithms/scheduling/diskscheduling/ScanScheduling.java",
        "symbol": "ScanScheduling.execute",
        "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/ScanScheduling.java",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[disk_size, head_position, direction, request_count, requests...]",
        "disk_size_range": [SCAN_MIN_DISK_SIZE, SCAN_MAX_DISK_SIZE],
        "head_position_range": "0 through disk_size - 1",
        "direction_values": {"0": "down", "1": "up"},
        "request_count_range": [0, SCAN_MAX_REQUEST_COUNT],
        "request_range": "0 through disk_size - 1",
        "maximum_valid_input_length": SCAN_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": SCAN_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 4 + request_count signed-i32 words.",
        "duplicates_allowed": True,
        "invalid_input_result": SCAN_INVALID_RESULT,
        "null_input_result": SCAN_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "Raw service-order positions; each nonempty request list also emits the source endpoint marker.",
        "empty_request_output": [],
        "valid_output_bytes_range": [0, SCAN_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": SCAN_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": SCAN_INVALID_RESULT,
        "null_output_result": SCAN_OUTPUT_ERROR,
        "insufficient_output_capacity_result": SCAN_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Invalid input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-java-scan-scheduling-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "scan_scheduling"
            or workload.get("function_symbol") != "scan_scheduling"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": SCAN_MAX_OUTPUT_BYTES,
                "meaning": "At most 64 requested positions plus one endpoint marker.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or SCAN_MIN_DISK_SIZE != 1 or SCAN_MAX_DISK_SIZE != 256
            or SCAN_MAX_REQUEST_COUNT != 64 or SCAN_MAX_INPUT_LENGTH != 68
            or SCAN_MAX_OUTPUT_BYTES != 260
            or SCAN_INVALID_RESULT != -1 or SCAN_OUTPUT_ERROR != -2
            or len(case_ids) != len(SCAN_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != SCAN_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 4
            or null_input_cases[0].get("expected_result") != SCAN_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_nonempty": SCAN_OUTPUT_ERROR,
                "null_output_empty": SCAN_OUTPUT_ERROR,
                "invalid_input_precedes_null_output": SCAN_INVALID_RESULT,
            }):
        raise ValueError("scan_scheduling workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "s" / "scan_scheduling" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "Moving up emits the right side" not in readme
            or "endpoint marker" not in readme):
        raise ValueError("scan_scheduling README is missing its pinned source or semantics")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not SCAN_I32_MIN <= value <= SCAN_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= SCAN_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= SCAN_MAX_OUTPUT_BYTES):
            raise ValueError(f"scan_scheduling workload framing is invalid: {case.get('id')}")
        result, output = scan_scheduling_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"scan_scheduling workload mismatch: {case.get('id')}")
    length_mismatch = next(case for case in workload["cases"]
                           if case.get("id") == "input_length_mismatch")
    if (len(length_mismatch["input_values"]) == length_mismatch["input_length"]
            or length_mismatch["expected_result"] != SCAN_INVALID_RESULT):
        raise ValueError("scan_scheduling is missing its input-length mismatch fixture")


MLFQ_CASE_IDS = frozenset({
    "empty_one_queue", "empty_four_queues", "one_queue_fcfs",
    "two_queues_round_robin_then_fcfs", "three_queues_two_round_robin_levels",
    "first_level_finishes_in_input_order", "demoted_processes_finish_fifo",
    "single_process_multiple_levels", "completion_at_slice_boundary", "maximum_input_and_output",
    "queue_count_zero", "queue_count_above_bound", "negative_process_count",
    "process_count_above_bound", "truncated_time_slice_list", "extra_time_slice_word",
    "truncated_burst_list", "extra_burst_word", "zero_time_slice", "time_slice_above_bound",
    "zero_burst", "burst_above_bound", "input_length_mismatch", "null_input_positive_length",
    "null_output_empty_result", "short_output_empty_result", "exact_output_empty_result",
    "null_output_nonempty_result", "short_output_nonempty_result", "exact_output_nonempty_result",
    "invalid_input_precedes_null_output",
})


def validate_mlfq_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "scheduling/multi_level_feedback_queue.py",
        "symbol": "MLFQ.multi_level_feedback_queue",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/multi_level_feedback_queue.py",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[queue_count, process_count, time_slices(queue_count - 1), burst_times(process_count)]",
        "queue_count_range": [1, MLFQ_MAX_QUEUE_COUNT],
        "process_count_range": [0, MLFQ_MAX_PROCESS_COUNT],
        "time_slice_count": "queue_count - 1",
        "time_slice_range": [1, MLFQ_MAX_TIME_SLICE],
        "burst_time_count": "process_count",
        "burst_time_range": [1, MLFQ_MAX_BURST_TIME],
        "arrival_times": "All processes arrive at time 0.",
        "implicit_process_names": "P0 through P(process_count - 1), assigned in burst input order.",
        "maximum_valid_input_length": MLFQ_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MLFQ_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 2 + (queue_count - 1) + process_count signed-i32 words.",
        "invalid_input_result": MLFQ_INVALID_RESULT,
        "null_input_result": MLFQ_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "[finished_count, (process_id, waiting_time, turnaround_time, stop_time)...] in finish order.",
        "process_id_mapping": "P0 maps to 0, P1 to 1, and so on.",
        "empty_process_output": [0],
        "valid_output_bytes_range": [4, MLFQ_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": MLFQ_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": MLFQ_INVALID_RESULT,
        "null_output_result": MLFQ_OUTPUT_ERROR,
        "insufficient_output_capacity_result": MLFQ_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Invalid input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-multi-level-feedback-queue-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "multi_level_feedback_queue"
            or workload.get("function_symbol") != "multi_level_feedback_queue"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": MLFQ_MAX_OUTPUT_BYTES,
                "meaning": "One finish-count word and at most eight four-i32 process records.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or MLFQ_MAX_QUEUE_COUNT != 4 or MLFQ_MAX_PROCESS_COUNT != 8
            or MLFQ_MAX_TIME_SLICE != 16 or MLFQ_MAX_BURST_TIME != 16
            or MLFQ_MAX_INPUT_LENGTH != 13 or MLFQ_MAX_OUTPUT_BYTES != 132
            or MLFQ_INVALID_RESULT != -1 or MLFQ_OUTPUT_ERROR != -2
            or len(case_ids) != len(MLFQ_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != MLFQ_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 2
            or null_input_cases[0].get("expected_result") != MLFQ_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_empty_result": MLFQ_OUTPUT_ERROR,
                "null_output_nonempty_result": MLFQ_OUTPUT_ERROR,
                "invalid_input_precedes_null_output": MLFQ_INVALID_RESULT,
            }):
        raise ValueError("multi_level_feedback_queue workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "multi_level_feedback_queue" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "arrivals fixed at time zero" not in readme
            or "finish-queue order" not in readme):
        raise ValueError("multi_level_feedback_queue README is missing its pinned source or bounded behavior")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not MLFQ_I32_MIN <= value <= MLFQ_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= MLFQ_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= MLFQ_MAX_OUTPUT_BYTES):
            raise ValueError(f"multi_level_feedback_queue workload framing is invalid: {case.get('id')}")
        result, output = mlfq_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"multi_level_feedback_queue workload mismatch: {case.get('id')}")
    length_mismatch = next(case for case in workload["cases"]
                           if case.get("id") == "input_length_mismatch")
    if (len(length_mismatch["input_values"]) == length_mismatch["input_length"]
            or length_mismatch["expected_result"] != MLFQ_INVALID_RESULT):
        raise ValueError("multi_level_feedback_queue is missing its input-length mismatch fixture")


PREEMPTIVE_CASE_IDS = frozenset({
    "empty_process_list", "single_process_immediate", "initial_idle_gap",
    "higher_priority_arrival_preempts", "equal_priority_older_arrival_keeps_turn",
    "multiple_preemptions", "same_arrival_priority_order", "equal_priority_uses_arrival_order",
    "input_order_differs_from_priority_order", "priority_i32_boundaries", "late_final_arrival",
    "maximum_80_ticks", "negative_process_count", "process_count_above_bound",
    "truncated_process_record", "trailing_process_record", "process_id_below_bound",
    "process_id_above_bound", "duplicate_process_id", "arrival_below_bound",
    "arrival_above_bound", "zero_burst", "burst_above_bound", "duplicate_priority_arrival_pair",
    "null_input_positive_length", "null_output_empty_list", "short_output_empty_list",
    "exact_output_empty_list", "null_output_nonempty", "short_output_nonempty",
    "exact_output_nonempty", "invalid_input_precedes_null_output",
})


def validate_preemptive_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Java",
        "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
        "path": "src/main/java/com/thealgorithms/scheduling/PreemptivePriorityScheduling.java",
        "symbol": "PreemptivePriorityScheduling.scheduleProcesses",
        "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/PreemptivePriorityScheduling.java",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[process_count, (process_id, arrival_time, burst_time, priority)...]",
        "process_count_range": [0, PREEMPTIVE_MAX_PROCESS_COUNT],
        "process_id_range": [0, PREEMPTIVE_MAX_PROCESS_ID],
        "process_ids_unique": True,
        "arrival_time_range": [0, PREEMPTIVE_MAX_ARRIVAL_TIME],
        "burst_time_range": [1, PREEMPTIVE_MAX_BURST_TIME],
        "priority_range": [PREEMPTIVE_I32_MIN, PREEMPTIVE_I32_MAX],
        "priority_arrival_pairs_unique": True,
        "process_id_mapping": "The adapter maps each integer ID to its decimal string for ProcessDetails and emits the same integer ID in the schedule.",
        "maximum_valid_input_length": PREEMPTIVE_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": PREEMPTIVE_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 1 + 4 * process_count signed-i32 words.",
        "invalid_input_result": PREEMPTIVE_INVALID_RESULT,
        "null_input_result": PREEMPTIVE_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "[tick_count, id_or_-1_for_idle...]",
        "idle_marker": -1,
        "empty_process_output": [0],
        "valid_output_bytes_range": [4, PREEMPTIVE_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": PREEMPTIVE_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": PREEMPTIVE_INVALID_RESULT,
        "null_output_result": PREEMPTIVE_OUTPUT_ERROR,
        "insufficient_output_capacity_result": PREEMPTIVE_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Invalid input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-java-preemptive-priority-scheduling-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "preemptive_priority_scheduling"
            or workload.get("function_symbol") != "preemptive_priority_scheduling"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": PREEMPTIVE_MAX_OUTPUT_BYTES,
                "meaning": "One tick-count word and at most 80 schedule ticks.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or PREEMPTIVE_MAX_PROCESS_COUNT != 8 or PREEMPTIVE_MAX_PROCESS_ID != 7
            or PREEMPTIVE_MAX_ARRIVAL_TIME != 16 or PREEMPTIVE_MAX_BURST_TIME != 8
            or PREEMPTIVE_MAX_INPUT_LENGTH != 33 or PREEMPTIVE_MAX_OUTPUT_BYTES != 324
            or PREEMPTIVE_INVALID_RESULT != -1 or PREEMPTIVE_OUTPUT_ERROR != -2
            or len(case_ids) != len(PREEMPTIVE_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != PREEMPTIVE_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 1
            or null_input_cases[0].get("expected_result") != PREEMPTIVE_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_empty_list": PREEMPTIVE_OUTPUT_ERROR,
                "null_output_nonempty": PREEMPTIVE_OUTPUT_ERROR,
                "invalid_input_precedes_null_output": PREEMPTIVE_INVALID_RESULT,
            }):
        raise ValueError("preemptive_priority_scheduling workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "p" / "preemptive_priority_scheduling" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "Higher numeric priority runs first" not in readme
            or "arrival time breaks priority ties" not in readme):
        raise ValueError("preemptive_priority_scheduling README is missing its pinned source or ordering rules")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not PREEMPTIVE_I32_MIN <= value <= PREEMPTIVE_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= PREEMPTIVE_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= PREEMPTIVE_MAX_OUTPUT_BYTES):
            raise ValueError(f"preemptive_priority_scheduling workload framing is invalid: {case.get('id')}")
        result, output = preemptive_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"preemptive_priority_scheduling workload mismatch: {case.get('id')}")


MULTIKEY_CASE_IDS = frozenset({
    "empty_list_exact_output", "one_empty_string", "one_ascii_string",
    "prefix_order_empty_and_duplicate_strings", "unsigned_ascii_byte_order",
    "accepted_ascii_control_and_boundary_bytes", "nine_items_use_insertion_sort",
    "ten_items_use_partition_path", "thirty_items_use_median_of_three",
    "thirty_two_items_use_pseudomedian_of_nine", "many_empty_strings_at_maximum_count",
    "shared_prefix_and_repeated_suffixes", "maximum_input_and_output",
    "short_output_capacity", "null_output_valid_empty_list",
    "null_output_valid_nonempty_list", "invalid_count_negative", "invalid_count_above_bound",
    "missing_count_word", "missing_string_length", "negative_string_length",
    "string_length_above_bound", "truncated_string_bytes", "trailing_word_after_empty_list",
    "nul_byte_rejected", "byte_above_ascii_rejected", "signed_i32_overflow_rejected",
    "nul_byte_rejected_before_later_malformed_record",
    "input_length_declared_short", "input_length_declared_long",
    "input_exceeds_parseable_word_bound", "null_input_positive_length",
    "invalid_input_precedes_null_output", "singleton_short_output_capacity",
    "singleton_exact_output_capacity",
})


def validate_multikey_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/C",
        "commit": "e5dad3fa8def3726ec850ca66a7f51521f8ad393",
        "path": "sorting/multikey_quick_sort.c",
        "symbol": "ssort2main",
        "url": "https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/multikey_quick_sort.c",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[count, (length, ASCII byte...) ...]",
        "string_count_range": [0, MULTIKEY_MAX_STRING_COUNT],
        "string_length_range": [0, MULTIKEY_MAX_STRING_LENGTH],
        "byte_range": [MULTIKEY_MIN_BYTE, MULTIKEY_MAX_BYTE],
        "byte_domain_reason": "ASCII bytes exclude NUL, which terminates C strings, and bytes above 127.",
        "ordering": "Ascending unsigned-ASCII lexicographic order; a shorter equal-prefix string comes first.",
        "maximum_valid_input_words": MULTIKEY_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_words": MULTIKEY_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 1 + sum(1 + string_length) signed-i32 words.",
        "invalid_input_result": MULTIKEY_INVALID_RESULT,
        "null_input_result": MULTIKEY_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "[count, (length, ASCII byte...) ...] in ascending lexicographic order.",
        "valid_output_bytes_range": [4, MULTIKEY_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": MULTIKEY_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": MULTIKEY_INVALID_RESULT,
        "null_output_result": MULTIKEY_OUTPUT_ERROR,
        "insufficient_output_capacity_result": MULTIKEY_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or out-of-domain input is rejected before output-buffer checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-c-multikey-quick-sort-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "multikey_quick_sort"
            or workload.get("function_symbol") != "multikey_quick_sort"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": MULTIKEY_MAX_OUTPUT_BYTES,
                "meaning": "One count word and up to 32 length-prefixed strings of 16 ASCII bytes each.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or MULTIKEY_MAX_STRING_COUNT != 32 or MULTIKEY_MAX_STRING_LENGTH != 16
            or MULTIKEY_MAX_VALID_INPUT_LENGTH != 545 or MULTIKEY_MAX_INPUT_LENGTH != 546
            or MULTIKEY_MAX_OUTPUT_BYTES != 2180 or MULTIKEY_I32_MIN != -(1 << 31)
            or MULTIKEY_I32_MAX != (1 << 31) - 1 or MULTIKEY_INVALID_RESULT != -1
            or MULTIKEY_OUTPUT_ERROR != -2
            or len(case_ids) != len(MULTIKEY_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != MULTIKEY_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 1
            or null_input_cases[0].get("expected_result") != MULTIKEY_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_valid_empty_list": MULTIKEY_OUTPUT_ERROR,
                "null_output_valid_nonempty_list": MULTIKEY_OUTPUT_ERROR,
                "invalid_input_precedes_null_output": MULTIKEY_INVALID_RESULT,
            }):
        raise ValueError("multikey_quick_sort workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "multikey_quick_sort" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme or "ssort2main" not in readme or "pseudomedian-of-nine" not in readme:
        raise ValueError("multikey_quick_sort README is missing its pinned source or algorithm path")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not MULTIKEY_I32_MIN <= value <= MULTIKEY_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= MULTIKEY_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= MULTIKEY_MAX_OUTPUT_BYTES):
            raise ValueError(f"multikey_quick_sort workload framing is invalid: {case.get('id')}")
        result, output = multikey_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"multikey_quick_sort workload mismatch: {case.get('id')}")


MAX_POOLING_CASE_IDS = frozenset({
    "single_pixel_exact_output", "whole_two_by_two_window", "two_by_two_pool_stride_one",
    "two_by_two_pool_stride_two", "nondivisible_edges_drop_partial_windows",
    "size_one_stride_one_preserves_all_values", "stride_larger_than_matrix_visits_first_window",
    "negative_pixels_choose_largest_value", "equal_maxima_across_windows",
    "pixel_domain_boundaries", "pool_size_equals_matrix_size", "stride_equals_matrix_size",
    "maximum_size_and_input", "maximum_output_size_one_by_one_windows",
    "maximum_side_length_stride_one", "short_output_capacity", "null_output_valid_input",
    "zero_matrix_size", "matrix_size_above_bound", "missing_matrix_parameters",
    "pool_size_zero", "pool_size_exceeds_matrix", "stride_zero", "stride_above_bound",
    "truncated_matrix", "trailing_matrix_word", "pixel_below_domain", "pixel_above_domain",
    "input_length_declared_short", "input_length_declared_long", "input_exceeds_parseable_bound",
    "null_input_positive_length", "invalid_input_precedes_null_output", "valid_exact_output_capacity",
})


def validate_max_pooling_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "computer_vision/pooling_functions.py",
        "symbol": "maxpooling",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/pooling_functions.py",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[n, size, stride, n*n row-major pixel values]",
        "matrix_size_range": [MAX_POOLING_MIN_MATRIX_SIZE, MAX_POOLING_MAX_MATRIX_SIZE],
        "pool_size_range": [MAX_POOLING_MIN_POOL_SIZE, MAX_POOLING_MAX_MATRIX_SIZE],
        "stride_range": [MAX_POOLING_MIN_STRIDE, MAX_POOLING_MAX_STRIDE],
        "pixel_range": [MAX_POOLING_MIN_PIXEL, MAX_POOLING_MAX_PIXEL],
        "shape_rule": "The matrix is square; pool_size must be no greater than n.",
        "maximum_valid_input_words": MAX_POOLING_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_words": MAX_POOLING_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 3 + n*n signed-i32 words.",
        "invalid_input_result": MAX_POOLING_INVALID_RESULT,
        "null_input_result": MAX_POOLING_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_ieee754_f64_array",
        "encoding": "Row-major max-pooled matrix values; no shape prefix.",
        "output_side_length": "(n - size) // stride + 1",
        "window_rule": "Only full windows are emitted; there is no padding.",
        "valid_output_bytes_range": [8, MAX_POOLING_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": MAX_POOLING_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": MAX_POOLING_INVALID_RESULT,
        "null_output_result": MAX_POOLING_OUTPUT_ERROR,
        "insufficient_output_capacity_result": MAX_POOLING_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Invalid or null input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-max-pooling-i32-array-f64-bytes-v1"
            or workload.get("algorithm") != "max_pooling"
            or workload.get("function_symbol") != "max_pooling"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": MAX_POOLING_MAX_OUTPUT_BYTES,
                "meaning": "Up to 16 by 16 IEEE-754 f64 max-pooling results.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or MAX_POOLING_MIN_MATRIX_SIZE != 1 or MAX_POOLING_MAX_MATRIX_SIZE != 16
            or MAX_POOLING_MIN_POOL_SIZE != 1
            or MAX_POOLING_MIN_STRIDE != 1 or MAX_POOLING_MAX_STRIDE != 16
            or MAX_POOLING_MIN_PIXEL != -1_000_000 or MAX_POOLING_MAX_PIXEL != 1_000_000
            or MAX_POOLING_MAX_VALID_INPUT_LENGTH != 259 or MAX_POOLING_MAX_INPUT_LENGTH != 260
            or MAX_POOLING_MAX_OUTPUT_BYTES != 2048 or MAX_POOLING_INVALID_RESULT != -1
            or MAX_POOLING_OUTPUT_ERROR != -2
            or len(case_ids) != len(MAX_POOLING_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != MAX_POOLING_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 3
            or null_input_cases[0].get("expected_result") != MAX_POOLING_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_valid_input": MAX_POOLING_OUTPUT_ERROR,
                "invalid_input_precedes_null_output": MAX_POOLING_INVALID_RESULT,
            }):
        raise ValueError("max_pooling workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "max_pooling" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme or "maxpooling" not in readme or "full windows" not in readme:
        raise ValueError("max_pooling README is missing its pinned source or window semantics")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not MAX_POOLING_I32_MIN <= value <= MAX_POOLING_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= MAX_POOLING_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= MAX_POOLING_MAX_OUTPUT_BYTES):
            raise ValueError(f"max_pooling workload framing is invalid: {case.get('id')}")
        result, output = max_pooling_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"max_pooling workload mismatch: {case.get('id')}")


RAT_MAZE_CASE_IDS = frozenset({
    "single_open_cell", "two_by_two_chooses_right_before_down",
    "right_branch_dead_end_backtracks_down", "pinned_four_by_four_sample",
    "blocked_destination_has_no_path", "open_start_without_open_neighbor",
    "maximum_eight_by_eight_open_maze", "exact_capacity_for_single_cell",
    "short_capacity_success_no_write", "null_output_success_no_write",
    "short_capacity_no_path_no_write", "blocked_source_precedes_output_errors",
    "null_input_precedes_output_errors", "zero_size_invalid", "nonbinary_cell_invalid",
    "trailing_cell_invalid", "declared_length_mismatch_invalid",
    "signed_i32_min_cell_invalid", "maximum_parseable_trailing_word_invalid",
})


def validate_rat_maze_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/C-Plus-Plus",
        "commit": "fdcc29b0ac2848e9d1a8d926e171cc5b39f97759",
        "path": "backtracking/rat_maze.cpp",
        "symbol": "backtracking::rat_maze::solveMaze",
        "url": "https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/rat_maze.cpp",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[n, n*n row-major cells]",
        "size_range": [RAT_MAZE_MIN_SIZE, RAT_MAZE_MAX_SIZE],
        "cell_values": [0, 1],
        "source_cell": "The top-left cell must be open (1).",
        "maximum_valid_input_words": RAT_MAZE_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_words": RAT_MAZE_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 1 + n*n signed-i32 words.",
        "invalid_input_result": RAT_MAZE_INVALID_RESULT,
        "null_input_result": RAT_MAZE_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "[0] when no path exists; [1, row-major path bits...] for the first path found by right-before-down DFS.",
        "single_cell_output": [1, 1],
        "valid_output_bytes_range": [4, RAT_MAZE_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": RAT_MAZE_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": RAT_MAZE_INVALID_RESULT,
        "null_output_result": RAT_MAZE_OUTPUT_ERROR,
        "insufficient_output_capacity_result": RAT_MAZE_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-cpp-rat-maze-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "rat_maze"
            or workload.get("function_symbol") != "rat_maze"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": RAT_MAZE_MAX_OUTPUT_BYTES,
                "meaning": "A found flag and up to 64 row-major path-cell words.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or RAT_MAZE_MIN_SIZE != 1 or RAT_MAZE_MAX_SIZE != 8
            or RAT_MAZE_MAX_VALID_INPUT_LENGTH != 65 or RAT_MAZE_MAX_INPUT_LENGTH != 66
            or RAT_MAZE_MAX_OUTPUT_BYTES != 260 or RAT_MAZE_INVALID_RESULT != -1
            or RAT_MAZE_OUTPUT_ERROR != -2
            or len(case_ids) != len(RAT_MAZE_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != RAT_MAZE_CASE_IDS):
        raise ValueError("rat_maze workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "rat_maze" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme or "right first" not in readme or "row-major" not in readme:
        raise ValueError("rat_maze README is missing its pinned source or traversal semantics")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not RAT_MAZE_I32_MIN <= value <= RAT_MAZE_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= RAT_MAZE_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= RAT_MAZE_MAX_OUTPUT_BYTES):
            raise ValueError(f"rat_maze workload framing is invalid: {case.get('id')}")
        result, output = rat_maze_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (type(case.get("expected_result")) is not int
                or case["expected_result"] != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"rat_maze workload mismatch: {case.get('id')}")


PRIMS_CASE_IDS = frozenset({
    "single_vertex_empty_graph_exact_output", "two_vertex_negative_edge",
    "triangle_distinct_weights", "equal_initial_keys_choose_right_child",
    "equal_candidate_keeps_first_parent", "decrease_key_updates_parent",
    "adjacency_input_order_tie_a", "adjacency_input_order_tie_b", "all_equal_weight_cycle",
    "negative_weight_graph", "signed_i32_boundary_weights", "source_documentation_graph",
    "edge_input_order_changes_tie_resolution", "maximum_input_and_output_64_edges",
    "valid_short_output", "valid_null_output", "connected_graph_short_output",
    "connected_graph_exact_output", "connected_graph_null_output", "zero_vertex_count",
    "vertex_count_above_bound", "negative_edge_count", "edge_count_above_bound",
    "disconnected_two_vertices", "disconnected_three_vertices", "truncated_edge_record",
    "trailing_edge_record", "self_edge", "reversed_endpoint_order", "endpoint_out_of_range",
    "duplicate_edge", "single_vertex_rejects_edges", "declared_input_length_short",
    "declared_input_length_long", "maximum_parseable_length_trailing_data",
    "null_input_positive_length", "invalid_graph_precedes_null_output",
})


def validate_minimum_spanning_tree_prims_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "graphs/minimum_spanning_tree_prims.py",
        "symbol": "prisms_algorithm",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_prims.py",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[vertex_count, edge_count, (u, v, weight)...]",
        "vertex_count_range": [PRIMS_MIN_VERTEX_COUNT, PRIMS_MAX_VERTEX_COUNT],
        "edge_count_range": [0, PRIMS_MAX_EDGE_COUNT],
        "weight_range": [PRIMS_I32_MIN, PRIMS_I32_MAX],
        "endpoint_rule": "Each edge has canonical endpoints 0 <= u < v < vertex_count.",
        "edge_uniqueness": "Each undirected edge appears at most once.",
        "connectedness": "The graph is connected for vertex_count > 1; vertex_count=1 requires edge_count=0.",
        "adjacency_order": "Append each edge to u and then v in input order.",
        "root_vertex": 0,
        "maximum_valid_input_length": PRIMS_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": PRIMS_MAX_PARSEABLE_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 2 + 3 * edge_count signed-i32 words.",
        "invalid_input_result": PRIMS_INVALID_RESULT,
        "null_input_result": PRIMS_INVALID_RESULT,
        "source_runtime_assumption": "The pinned source's sys.maxsize heap sentinel is fixed to 2^63-1 (64-bit Python runtime); every signed-i32 edge weight is strictly smaller.",
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "[n-1, (parent, child)...] in extraction order; weights are omitted.",
        "single_vertex_output": [0],
        "valid_output_bytes_range": [4, PRIMS_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": PRIMS_MAX_OUTPUT_BYTES,
        "success_result": "output byte length",
        "invalid_input_result": PRIMS_INVALID_RESULT,
        "null_output_result": PRIMS_OUTPUT_ERROR,
        "insufficient_output_capacity_result": PRIMS_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or disconnected input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-minimum-spanning-tree-prims-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "minimum_spanning_tree_prims"
            or workload.get("function_symbol") != "minimum_spanning_tree_prims"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": PRIMS_MAX_OUTPUT_BYTES,
                "meaning": "One edge-count word and up to 15 parent-child pairs.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or PRIMS_MIN_VERTEX_COUNT != 1 or PRIMS_MAX_VERTEX_COUNT != 16
            or PRIMS_MAX_EDGE_COUNT != 64 or PRIMS_MAX_INPUT_LENGTH != 194
            or PRIMS_MAX_PARSEABLE_INPUT_LENGTH != 195 or PRIMS_MAX_OUTPUT_BYTES != 124
            or PRIMS_SOURCE_HEAP_SENTINEL != (1 << 63) - 1
            or PRIMS_INVALID_RESULT != -1 or PRIMS_OUTPUT_ERROR != -2
            or len(case_ids) != len(PRIMS_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != PRIMS_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 2
            or null_input_cases[0].get("expected_result") != PRIMS_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "valid_null_output": PRIMS_OUTPUT_ERROR,
                "connected_graph_null_output": PRIMS_OUTPUT_ERROR,
                "invalid_graph_precedes_null_output": PRIMS_INVALID_RESULT,
            }):
        raise ValueError("minimum_spanning_tree_prims workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "minimum_spanning_tree_prims" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "sys.maxsize" not in readme
            or "right child when child keys tie" not in readme):
        raise ValueError("minimum_spanning_tree_prims README is missing its pinned source or heap semantics")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not PRIMS_I32_MIN <= value <= PRIMS_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= PRIMS_MAX_PARSEABLE_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= PRIMS_MAX_OUTPUT_BYTES):
            raise ValueError(f"minimum_spanning_tree_prims workload framing is invalid: {case.get('id')}")
        result, output = prims_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (type(case.get("expected_result")) is not int
                or case["expected_result"] != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"minimum_spanning_tree_prims workload mismatch: {case.get('id')}")


MO_CASE_IDS = frozenset({
    "one_value_single_query", "all_equal_repeated_queries",
    "all_distinct_singletons_and_full_range", "queries_returned_in_original_order",
    "block_boundary_queries", "ceil_sqrt_seven_element_array",
    "maximum_n_queries_and_output", "zero_queries_empty_output",
    "zero_queries_null_output_empty_result", "exact_capacity_for_two_answers",
    "short_capacity_with_queries_no_write", "null_output_with_query_no_write",
    "null_input_positive_length", "invalid_query_before_null_output",
    "zero_left_bound_invalid", "reversed_query_bounds_invalid",
    "value_below_domain_invalid", "value_above_domain_invalid", "zero_array_size_invalid",
    "query_count_above_bound_invalid", "trailing_word_invalid",
    "maximum_parseable_trailing_word_invalid", "invalid_input_before_short_capacity",
})


def validate_mo_workload(workload: dict) -> None:
    sources = [
        {
            "repository": "TheAlgorithms/C-Plus-Plus",
            "commit": "fdcc29b0ac2848e9d1a8d926e171cc5b39f97759",
            "path": "range_queries/mo.cpp",
            "symbol": "main",
            "url": "https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/mo.cpp",
        },
        {
            "repository": "TheAlgorithms/C-Plus-Plus-1",
            "commit": "0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680",
            "path": "range_queries/mo.cpp",
            "symbol": "main",
            "url": "https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/mo.cpp",
        },
    ]
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[n, values[n], q, (left, right)*q]",
        "array_size_range": [MO_MIN_ARRAY_SIZE, MO_MAX_ARRAY_SIZE],
        "value_range": [MO_MIN_VALUE, MO_MAX_VALUE],
        "query_count_range": [MO_MIN_QUERY_COUNT, MO_MAX_QUERY_COUNT],
        "query_bounds": "One-based inclusive; every query satisfies 1 <= left <= right <= n.",
        "maximum_valid_input_length": MO_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_length": MO_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 2 + n + 2*q signed-i32 words.",
        "invalid_input_result": MO_INVALID_RESULT,
        "null_input_result": MO_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "Exactly q distinct-count values in original query order; no count prefix.",
        "empty_query_output": [],
        "valid_output_bytes_range": [0, MO_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": MO_MAX_OUTPUT_BYTES,
        "success_result": "output byte length (4*q)",
        "invalid_input_result": MO_INVALID_RESULT,
        "null_output_result": MO_OUTPUT_ERROR,
        "insufficient_output_capacity_result": MO_OUTPUT_ERROR,
        "zero_query_null_output_result": MO_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
    }
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-cpp-mo-distinct-range-queries-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "mo"
            or workload.get("function_symbol") != "mo"
            or workload.get("pinned_sources") != sources
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": MO_MAX_OUTPUT_BYTES,
                "meaning": "Up to 64 signed-i32 query answers.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or MO_MIN_ARRAY_SIZE != 1 or MO_MAX_ARRAY_SIZE != 64
            or MO_MIN_QUERY_COUNT != 0 or MO_MAX_QUERY_COUNT != 64
            or MO_MIN_VALUE != 0 or MO_MAX_VALUE != 255
            or MO_MAX_VALID_INPUT_LENGTH != 194 or MO_MAX_INPUT_LENGTH != 195
            or MO_MAX_OUTPUT_BYTES != 256
            or MO_INVALID_RESULT != -1 or MO_OUTPUT_ERROR != -2
            or len(case_ids) != len(MO_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != MO_CASE_IDS
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 1
            or null_input_cases[0].get("output_is_null") is not False
            or null_input_cases[0].get("expected_result") != MO_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "zero_queries_null_output_empty_result": MO_OUTPUT_ERROR,
                "null_output_with_query_no_write": MO_OUTPUT_ERROR,
                "invalid_query_before_null_output": MO_INVALID_RESULT,
            }):
        raise ValueError("mo workload metadata or case IDs do not match the reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "mo" / "README.md").read_text(encoding="utf-8")
    if (any(source["url"] not in readme for source in sources)
            or "ceil(sqrt(n))" not in readme
            or "zero-query" not in readme):
        raise ValueError("mo README is missing pinned sources or its zero-query contract")
    for case in workload["cases"]:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not MO_I32_MIN <= value <= MO_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= MO_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError(f"mo workload framing is invalid: {case.get('id')}")
        result, output = mo_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (type(case.get("expected_result")) is not int
                or case["expected_result"] != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"mo workload mismatch: {case.get('id')}")


HUNGARIAN_CASE_IDS = frozenset({
    "one_by_one_zero_cost", "one_by_one_maximum_cost", "square_all_zero_tie",
    "tall_all_zero_tie", "wide_all_zero_tie", "rectangular_unique_minimum",
    "maximum_dimensions_and_costs", "exact_capacity_one_by_one", "short_capacity_no_write",
    "null_output_no_write", "null_input_positive_length", "invalid_input_precedes_null_output",
    "zero_rows", "zero_columns", "negative_cost", "cost_above_limit", "trailing_word",
    "maximum_parseable_trailing_word", "input_length_mismatch",
})


def validate_hungarian_algorithm_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Java",
        "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
        "path": "src/main/java/com/thealgorithms/graph/HungarianAlgorithm.java",
        "symbol": "solve",
        "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HungarianAlgorithm.java",
    }
    input_spec = {
        "kind": "signed_i32_array",
        "encoding": "[rows, cols, costs...] with costs flattened row-major and no count prefix.",
        "row_count_range": [HUNGARIAN_MIN_DIMENSION, HUNGARIAN_MAX_DIMENSION],
        "column_count_range": [HUNGARIAN_MIN_DIMENSION, HUNGARIAN_MAX_DIMENSION],
        "cost_range": [HUNGARIAN_MIN_COST, HUNGARIAN_MAX_COST],
        "maximum_valid_input_length": HUNGARIAN_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_length": HUNGARIAN_MAX_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 2 + rows*cols signed-i32 words.",
        "invalid_input_result": HUNGARIAN_INVALID_RESULT,
        "null_input_result": HUNGARIAN_INVALID_RESULT,
    }
    output_spec = {
        "kind": "little_endian_signed_i32_array",
        "encoding": "Exactly rows zero-based column assignments (or -1 for a padded column), followed by total cost; no count prefix.",
        "valid_output_bytes_range": [8, HUNGARIAN_MAX_OUTPUT_BYTES],
        "maximum_output_bytes": HUNGARIAN_MAX_OUTPUT_BYTES,
        "success_result": "output byte length (4*(rows+1))",
        "invalid_input_result": HUNGARIAN_INVALID_RESULT,
        "null_output_result": HUNGARIAN_OUTPUT_ERROR,
        "insufficient_output_capacity_result": HUNGARIAN_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
    }
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-java-hungarian-algorithm-i32-array-bytes-output-v1"
            or workload.get("algorithm") != "hungarian_algorithm"
            or workload.get("function_symbol") != "hungarian_algorithm"
            or workload.get("pinned_sources") != [source]
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "bytes": HUNGARIAN_MAX_OUTPUT_BYTES,
                "meaning": "Up to eight signed-i32 row assignments followed by total cost.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or HUNGARIAN_MIN_DIMENSION != 1 or HUNGARIAN_MAX_DIMENSION != 8
            or HUNGARIAN_MIN_COST != 0 or HUNGARIAN_MAX_COST != 1000
            or HUNGARIAN_MAX_VALID_INPUT_LENGTH != 66 or HUNGARIAN_MAX_INPUT_LENGTH != 67
            or HUNGARIAN_MAX_OUTPUT_BYTES != 36
            or HUNGARIAN_INVALID_RESULT != -1 or HUNGARIAN_OUTPUT_ERROR != -2
            or not isinstance(cases, list)
            or len(case_ids) != len(HUNGARIAN_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != HUNGARIAN_CASE_IDS):
        raise ValueError("hungarian_algorithm workload metadata or case IDs do not match the reviewed contract")

    readme = (ROOT / "benchmarks" / "h" / "hungarian_algorithm" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "zero-padding" not in readme
            or "ascending order" not in readme or "little-endian" not in readme):
        raise ValueError("hungarian_algorithm README is missing its pinned source or assignment semantics")
    null_input_cases = [case for case in cases if case.get("input_is_null", False)]
    null_output_cases = [case for case in cases if case.get("output_is_null", False)]
    if (len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input_positive_length"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 1
            or null_input_cases[0].get("expected_result") != HUNGARIAN_INVALID_RESULT
            or {case.get("id"): case.get("expected_result") for case in null_output_cases} != {
                "null_output_no_write": HUNGARIAN_OUTPUT_ERROR,
                "invalid_input_precedes_null_output": HUNGARIAN_INVALID_RESULT,
            }):
        raise ValueError("hungarian_algorithm workload is missing required pointer-precedence cases")
    for case in cases:
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or len(values) > HUNGARIAN_MAX_INPUT_LENGTH
                or any(type(value) is not int or not HUNGARIAN_I32_MIN <= value <= HUNGARIAN_I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= HUNGARIAN_MAX_INPUT_LENGTH
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError(f"hungarian_algorithm workload framing is invalid: {case.get('id')}")
        result, output = hungarian_expected_output(
            values, capacity, output_is_null, input_is_null, input_length)
        if (type(case.get("expected_result")) is not int
                or case["expected_result"] != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"hungarian_algorithm workload mismatch: {case.get('id')}")


def fnv1a(data: bytes) -> int:
    result = 14695981039346656037
    for value in data:
        result = ((result ^ value) * 1099511628211) & ((1 << 64) - 1)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", required=True, type=Path)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()

    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("family") != "i32_array_bytes_output":
        parser.error("build manifest must declare the i32_array_bytes_output ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    if algorithm not in ALGORITHMS:
        parser.error(f"no i32 array byte-output recorder for {algorithm}")
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i32_array_bytes_output_runner"]
    executable = Path(binary["path"])
    harness = ROOT / "benchmarks" / "harness" / "i32_array_bytes_output_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(harness) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    default_workload = (ROOT / "benchmarks" / "m" / "rat_maze" / "workload.json"
                        if algorithm == "rat_maze" else
                        ROOT / "benchmarks" / letter / algorithm / "workload.json")
    workload_path = args.workload or default_workload
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model")
            != "i32_array_bytes_output_call"):
        parser.error("workload does not match the built i32 byte-output algorithm")
    if algorithm == "minimum_spanning_tree_kruskal2":
        validate_kruskal2_workload(workload)
    elif algorithm == "scan_scheduling":
        validate_scan_scheduling_workload(workload)
    elif algorithm == "multi_level_feedback_queue":
        validate_mlfq_workload(workload)
    elif algorithm == "preemptive_priority_scheduling":
        validate_preemptive_workload(workload)
    elif algorithm == "multikey_quick_sort":
        validate_multikey_workload(workload)
    elif algorithm == "max_pooling":
        validate_max_pooling_workload(workload)
    elif algorithm == "rat_maze":
        validate_rat_maze_workload(workload)
    elif algorithm == "minimum_spanning_tree_prims":
        validate_minimum_spanning_tree_prims_workload(workload)
    elif algorithm == "mo":
        validate_mo_workload(workload)
    elif algorithm == "hungarian_algorithm":
        validate_hungarian_algorithm_workload(workload)
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed the runner limits")
    if len({case["id"] for case in workload["cases"]}) != len(workload["cases"]):
        parser.error("workload case IDs must be unique")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": binary["harness_sha256"],
                           "binary_sha256": binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case in workload["cases"]:
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        parseable_input_length = max_parseable_input_length(algorithm)
        if (not isinstance(values, list)
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values)
                or type(input_is_null) is not bool
                or len(values) > parseable_input_length):
            raise ValueError(f"invalid signed-i32 input array in {case['id']}")
        if input_is_null:
            if (values or type(input_length) is not int
                    or not 1 <= input_length <= parseable_input_length):
                raise ValueError(f"null input must have an empty payload and positive declared length in {case['id']}")
        elif (type(input_length) is not int
                or not 0 <= input_length <= parseable_input_length):
            raise ValueError(f"declared input length is out of range in {case['id']}")

        output_is_null = case.get("output_is_null", False)
        default_capacity = (workload.get("workspace") or {}).get(
            "bytes", len(bytes.fromhex(case.get("expected_output_hex", ""))))
        output_capacity = case.get("workspace_bytes", case.get("output_capacity", default_capacity))
        if (type(output_is_null) is not bool or (input_is_null and output_is_null)
                or type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError(f"invalid output pointer or capacity in {case['id']}")
        expected_count, expected_output = oracle_for(
            values, algorithm, output_capacity, output_is_null, input_is_null, input_length)
        if (case.get("expected_result") != expected_count
                or case.get("expected_output_hex", "").lower() != expected_output.hex()):
            raise ValueError(f"workload oracle mismatch for {case['id']}")
        if (expected_count >= 0 and len(expected_output) > max_output_bytes(algorithm)
                or expected_count < 0 and expected_output):
            raise ValueError(f"invalid oracle result framing for {case['id']}")

        output_hex = expected_output.hex() if expected_output else "-"
        if input_is_null:
            command = [str(executable), "--null-input", str(samples), str(warmups), str(repetitions)]
            runner_input = (f"{input_length} {expected_count} {len(expected_output)} "
                            f"{output_capacity} {output_hex}\n")
        else:
            command = [str(executable), "--stdin", str(samples), str(warmups), str(repetitions)]
            runner_input = (f"{len(values)} {input_length} {expected_count} "
                            f"{len(expected_output)} {output_capacity} "
                            + " ".join(map(str, values)) + " " + output_hex)
            if output_is_null:
                runner_input += " null_output 1"
            runner_input += "\n"
        completed = subprocess.run(command, input=runner_input, capture_output=True,
                                   text=True, check=False, timeout=120)
        if completed.returncode:
            raise SystemExit(f"byte-output runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = (fnv1a(expected_output) * repetitions * samples) & ((1 << 64) - 1)
        if (raw["observed_result"] != expected_count or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"byte-output runner returned an invalid result for {case['id']}")

        workload_record = {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                           "input_length": input_length, "input_values": values,
                           "case": case["id"], "target": None,
                           "output_capacity": output_capacity, "output_is_null": output_is_null,
                           "expected_result": expected_count}
        if input_is_null:
            workload_record["input_is_null"] = True
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": workload_record,
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i32_array_bytes_output_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"],
                                        "observed_result": raw["observed_result"],
                                        "result_checksum": raw["result_checksum"]}})

    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
