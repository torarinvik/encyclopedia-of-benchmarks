#!/usr/bin/env python3
"""Verify signed-i32 array byte-output ports against their reviewed oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from salsa_oracle import (
    I32_MAX, I32_MIN, INVALID_RESULT, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH, OUTPUT_ERROR_RESULT, expected_output as salsa_oracle,
)
from steinhaus_johnson_trotter_oracle import INVALID_RESULT as SJT_INVALID_RESULT
from steinhaus_johnson_trotter_oracle import MAX_LENGTH as SJT_MAX_LENGTH
from steinhaus_johnson_trotter_oracle import MAX_OUTPUT_BYTES as SJT_MAX_OUTPUT_BYTES
from steinhaus_johnson_trotter_oracle import MAX_PARSEABLE_INPUT_LENGTH as SJT_MAX_PARSEABLE_INPUT_LENGTH
from steinhaus_johnson_trotter_oracle import MIN_LENGTH as SJT_MIN_LENGTH
from steinhaus_johnson_trotter_oracle import OUTPUT_ERROR_RESULT as SJT_OUTPUT_ERROR_RESULT
from steinhaus_johnson_trotter_oracle import expected_output as sjt_oracle
from minimum_spanning_tree_kruskal2_oracle import I32_MAX as KRUSKAL2_I32_MAX
from minimum_spanning_tree_kruskal2_oracle import I32_MIN as KRUSKAL2_I32_MIN
from minimum_spanning_tree_kruskal2_oracle import INVALID_RESULT as KRUSKAL2_INVALID_RESULT
from minimum_spanning_tree_kruskal2_oracle import MAX_EDGE_COUNT as KRUSKAL2_MAX_EDGE_COUNT
from minimum_spanning_tree_kruskal2_oracle import MAX_INPUT_LENGTH as KRUSKAL2_MAX_INPUT_LENGTH
from minimum_spanning_tree_kruskal2_oracle import MAX_OUTPUT_BYTES as KRUSKAL2_MAX_OUTPUT_BYTES
from minimum_spanning_tree_kruskal2_oracle import MAX_VERTEX_COUNT as KRUSKAL2_MAX_VERTEX_COUNT
from minimum_spanning_tree_kruskal2_oracle import MIN_VERTEX_COUNT as KRUSKAL2_MIN_VERTEX_COUNT
from minimum_spanning_tree_kruskal2_oracle import OUTPUT_ERROR as KRUSKAL2_OUTPUT_ERROR
from minimum_spanning_tree_kruskal2_oracle import expected_output as kruskal2_oracle
from scan_scheduling_oracle import I32_MAX as SCAN_I32_MAX
from scan_scheduling_oracle import I32_MIN as SCAN_I32_MIN
from scan_scheduling_oracle import INVALID_RESULT as SCAN_INVALID_RESULT
from scan_scheduling_oracle import MAX_DISK_SIZE as SCAN_MAX_DISK_SIZE
from scan_scheduling_oracle import MAX_INPUT_LENGTH as SCAN_MAX_INPUT_LENGTH
from scan_scheduling_oracle import MAX_OUTPUT_BYTES as SCAN_MAX_OUTPUT_BYTES
from scan_scheduling_oracle import MAX_REQUEST_COUNT as SCAN_MAX_REQUEST_COUNT
from scan_scheduling_oracle import MIN_DISK_SIZE as SCAN_MIN_DISK_SIZE
from scan_scheduling_oracle import OUTPUT_ERROR as SCAN_OUTPUT_ERROR
from scan_scheduling_oracle import expected_output as scan_scheduling_oracle
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
from multi_level_feedback_queue_oracle import expected_output as mlfq_oracle
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
from preemptive_priority_scheduling_oracle import expected_output as preemptive_oracle
from multikey_quick_sort_oracle import I32_MAX as MULTIKEY_I32_MAX
from multikey_quick_sort_oracle import I32_MIN as MULTIKEY_I32_MIN
from multikey_quick_sort_oracle import INVALID_RESULT as MULTIKEY_INVALID_RESULT
from multikey_quick_sort_oracle import MAX_BYTE as MULTIKEY_MAX_BYTE
from multikey_quick_sort_oracle import MAX_OUTPUT_BYTES as MULTIKEY_MAX_OUTPUT_BYTES
from multikey_quick_sort_oracle import MAX_PARSEABLE_INPUT_WORDS as MULTIKEY_MAX_INPUT_LENGTH
from multikey_quick_sort_oracle import MAX_STRING_COUNT as MULTIKEY_MAX_STRING_COUNT
from multikey_quick_sort_oracle import MAX_STRING_LENGTH as MULTIKEY_MAX_STRING_LENGTH
from multikey_quick_sort_oracle import MIN_BYTE as MULTIKEY_MIN_BYTE
from multikey_quick_sort_oracle import OUTPUT_ERROR as MULTIKEY_OUTPUT_ERROR
from multikey_quick_sort_oracle import expected_output as multikey_oracle
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
from max_pooling_oracle import expected_output as max_pooling_oracle
from rat_maze_oracle import I32_MAX as RAT_MAZE_I32_MAX
from rat_maze_oracle import I32_MIN as RAT_MAZE_I32_MIN
from rat_maze_oracle import INVALID_RESULT as RAT_MAZE_INVALID_RESULT
from rat_maze_oracle import MAX_INPUT_WORDS as RAT_MAZE_MAX_VALID_INPUT_LENGTH
from rat_maze_oracle import MAX_OUTPUT_BYTES as RAT_MAZE_MAX_OUTPUT_BYTES
from rat_maze_oracle import MAX_PARSEABLE_INPUT_WORDS as RAT_MAZE_MAX_INPUT_LENGTH
from rat_maze_oracle import MAX_SIZE as RAT_MAZE_MAX_SIZE
from rat_maze_oracle import MIN_SIZE as RAT_MAZE_MIN_SIZE
from rat_maze_oracle import OUTPUT_ERROR as RAT_MAZE_OUTPUT_ERROR
from rat_maze_oracle import expected_output as rat_maze_oracle
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
from minimum_spanning_tree_prims_oracle import expected_output as prims_oracle
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
from mo_oracle import expected_output as mo_oracle
from hungarian_algorithm_oracle import I32_MAX as HUNGARIAN_I32_MAX
from hungarian_algorithm_oracle import I32_MIN as HUNGARIAN_I32_MIN
from hungarian_algorithm_oracle import INVALID_RESULT as HUNGARIAN_INVALID_RESULT
from hungarian_algorithm_oracle import MAX_COST as HUNGARIAN_MAX_COST
from hungarian_algorithm_oracle import MAX_DIMENSION as HUNGARIAN_MAX_DIMENSION
from hungarian_algorithm_oracle import MAX_OUTPUT_BYTES as HUNGARIAN_MAX_OUTPUT_BYTES
from hungarian_algorithm_oracle import MAX_PARSEABLE_INPUT_WORDS as HUNGARIAN_MAX_INPUT_LENGTH
from hungarian_algorithm_oracle import MAX_VALID_INPUT_WORDS as HUNGARIAN_MAX_VALID_INPUT_LENGTH
from hungarian_algorithm_oracle import OUTPUT_ERROR as HUNGARIAN_OUTPUT_ERROR
from hungarian_algorithm_oracle import expected_output as hungarian_oracle
from merge_sort_no_extra_space_oracle import INVALID_RESULT as MERGE_SORT_INVALID_RESULT
from merge_sort_no_extra_space_oracle import MAX_LENGTH as MERGE_SORT_MAX_LENGTH
from merge_sort_no_extra_space_oracle import MAX_OUTPUT_BYTES as MERGE_SORT_MAX_OUTPUT_BYTES
from merge_sort_no_extra_space_oracle import MAX_PARSEABLE_LENGTH as MERGE_SORT_MAX_PARSEABLE_LENGTH
from merge_sort_no_extra_space_oracle import MAX_VALUE as MERGE_SORT_MAX_VALUE
from merge_sort_no_extra_space_oracle import MIN_VALUE as MERGE_SORT_MIN_VALUE
from merge_sort_no_extra_space_oracle import OUTPUT_ERROR as MERGE_SORT_OUTPUT_ERROR
from merge_sort_no_extra_space_oracle import expected_output as merge_sort_no_extra_space_oracle
from reverse_singly_linked_list_oracle import INVALID_RESULT as REVERSE_LIST_INVALID_RESULT
from reverse_singly_linked_list_oracle import MAX_LENGTH as REVERSE_LIST_MAX_LENGTH
from reverse_singly_linked_list_oracle import MAX_OUTPUT_BYTES as REVERSE_LIST_MAX_OUTPUT_BYTES
from reverse_singly_linked_list_oracle import MAX_PARSEABLE_LENGTH as REVERSE_LIST_MAX_PARSEABLE_LENGTH
from reverse_singly_linked_list_oracle import OUTPUT_ERROR as REVERSE_LIST_OUTPUT_ERROR
from reverse_kgroup_oracle import INVALID_RESULT as REVERSE_KGROUP_INVALID_RESULT
from reverse_kgroup_oracle import MAX_LIST_LENGTH as REVERSE_KGROUP_MAX_LIST_LENGTH
from reverse_kgroup_oracle import MAX_OUTPUT_BYTES as REVERSE_KGROUP_MAX_OUTPUT_BYTES
from reverse_kgroup_oracle import MAX_PARSEABLE_INPUT_LENGTH as REVERSE_KGROUP_MAX_PARSEABLE_INPUT_LENGTH
from reverse_kgroup_oracle import MAX_VALID_INPUT_LENGTH as REVERSE_KGROUP_MAX_VALID_INPUT_LENGTH
from reverse_kgroup_oracle import OUTPUT_ERROR as REVERSE_KGROUP_OUTPUT_ERROR
from snail_oracle import INVALID_RESULT as SNAIL_INVALID_RESULT
from snail_oracle import MAX_COLUMNS as SNAIL_MAX_COLUMNS
from snail_oracle import MAX_OUTPUT_BYTES as SNAIL_MAX_OUTPUT_BYTES
from snail_oracle import MAX_PARSEABLE_INPUT_LENGTH as SNAIL_MAX_PARSEABLE_INPUT_LENGTH
from snail_oracle import MAX_ROWS as SNAIL_MAX_ROWS
from snail_oracle import MAX_VALID_INPUT_LENGTH as SNAIL_MAX_VALID_INPUT_LENGTH
from snail_oracle import OUTPUT_ERROR as SNAIL_OUTPUT_ERROR
from run_i32_array_bytes_output import (
    validate_kruskal2_workload, validate_mlfq_workload,
    validate_max_pooling_workload, validate_multikey_workload,
    validate_minimum_spanning_tree_prims_workload, validate_preemptive_workload,
    validate_hungarian_algorithm_workload, validate_mo_workload, validate_rat_maze_workload,
    validate_scan_scheduling_workload, validate_merge_sort_no_extra_space_workload,
    validate_reverse_singly_linked_list_workload,
    validate_snail_workload,
    validate_reverse_kgroup_workload,
    validate_sjfscheduling_workload,
)

ALGORITHMS = ("salsa", "steinhaus_johnson_trotter", "minimum_spanning_tree_kruskal2",
              "scan_scheduling", "multi_level_feedback_queue", "rat_maze",
              "minimum_spanning_tree_prims",
              "mo",
              "preemptive_priority_scheduling",
              "multikey_quick_sort", "max_pooling", "hungarian_algorithm",
              "merge_sort_no_extra_space", "reverse_singly_linked_list", "snail",
              "reverse_kgroup", "sjfscheduling")
MAX_OUTPUT_CAPACITY = 400004


def salsa_corpus(workload: dict) -> tuple[str, int]:
    source = {
        "repository": "TheAlgorithms/Rust",
        "commit": "fed66cb0c74a939ec5163648458a8c2b46fd4c",
        "path": "src/ciphers/salsa.rs",
        "symbol": "salsa20",
        "url": "https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/ciphers/salsa.rs",
    }
    required_case_ids = {
        "pinned_wikipedia_variant_test_vector", "truncated_state", "extra_state_word",
        "null_input", "null_output", "short_output_capacity",
    }
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_cases = [case for case in workload.get("cases", [])
                        if case.get("input_is_null", False)]
    null_output_cases = [case for case in workload.get("cases", [])
                         if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-rust-salsa-pinned-core-variant-i32-v1"
            or workload.get("algorithm") != "salsa"
            or workload.get("function_symbol") != "salsa"
            or workload.get("pinned_source") != source
            or workload.get("variant_caveat") != (
                "This pinned core variant matches the source's Wikipedia test vector but differs from "
                "Bernstein's original Salsa20 spec PDF; do not claim standards conformance."
            )
            or input_spec != {
                "kind": "signed_i32_array",
                "layout": "16 signed-i32 slots interpreted as raw u32 words in source array order",
                "slot_range": [I32_MIN, I32_MAX],
                "exact_length": MAX_VALID_INPUT_LENGTH,
                "maximum_valid_array_length": MAX_VALID_INPUT_LENGTH,
                "maximum_parseable_array_length": MAX_PARSEABLE_INPUT_LENGTH,
                "invalid_input_result": INVALID_RESULT,
                "null_input_result": INVALID_RESULT,
            }
            or output_spec != {
                "kind": "pinned_salsa_core_u32_word_bytes",
                "encoding": "16 output words serialized as little-endian u32 values",
                "success_result": MAX_OUTPUT_BYTES,
                "maximum_output_bytes": MAX_OUTPUT_BYTES,
                "invalid_input_result": INVALID_RESULT,
                "null_output_result": OUTPUT_ERROR_RESULT,
                "insufficient_output_capacity_result": OUTPUT_ERROR_RESULT,
                "no_write_on_error": True,
            }
            or workload.get("workspace") != {
                "bytes": MAX_OUTPUT_BYTES,
                "meaning": "Sixteen little-endian u32 output words.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 5,
                "warmup_rounds": 1,
                "repetitions_per_sample": 100,
            }
            or I32_MIN != -(1 << 31) or I32_MAX != (1 << 31) - 1
            or MAX_VALID_INPUT_LENGTH != 16 or MAX_PARSEABLE_INPUT_LENGTH != 17
            or MAX_OUTPUT_BYTES != 64 or INVALID_RESULT != -1 or OUTPUT_ERROR_RESULT != -2
            or len(case_ids) != len(required_case_ids)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != required_case_ids
            or len(null_input_cases) != 1
            or null_input_cases[0].get("id") != "null_input"
            or null_input_cases[0].get("input_values") != []
            or null_input_cases[0].get("input_length") != 1
            or null_input_cases[0].get("expected_result") != INVALID_RESULT
            or len(null_output_cases) != 1
            or null_output_cases[0].get("id") != "null_output"
            or null_output_cases[0].get("expected_result") != OUTPUT_ERROR_RESULT
            or any(case.get("input_length", len(case.get("input_values", ())))
                   != len(case.get("input_values", ()))
                   for case in workload.get("cases", [])
                   if not case.get("input_is_null", False))):
        raise ValueError("salsa workload metadata does not match its reviewed i32 contract")

    readme = (ROOT / "benchmarks" / "s" / "salsa" / "README.md").read_text(encoding="utf-8")
    if (source["url"] not in readme or "does not agree" not in readme
            or "must not be described as standards-conformant" not in readme):
        raise ValueError("salsa README is missing its pinned source or variant compatibility caveat")
    vector = next(case for case in workload["cases"]
                  if case.get("id") == "pinned_wikipedia_variant_test_vector")
    if (len(vector.get("input_values", ())) != MAX_VALID_INPUT_LENGTH
            or vector.get("expected_result") != MAX_OUTPUT_BYTES
            or vector.get("expected_output_hex", "").lower()
                != "8d6f1dde9df6db910cb7b40dd220438b32446936b0986d896db7a75a13ca385"
                   "770a1e504af79e4c82fed4215a56bf2300302a27dc655e9cfa0c74c6f5943d36d"):
        raise ValueError("salsa workload is missing its pinned source vector")
    short_capacity = next(case for case in workload["cases"]
                          if case.get("id") == "short_output_capacity")
    if (short_capacity.get("output_capacity") != MAX_OUTPUT_BYTES - 1
            or short_capacity.get("expected_result") != OUTPUT_ERROR_RESULT):
        raise ValueError("salsa workload is missing short-capacity coverage")

    default_capacity = MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False) -> None:
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("salsa input exceeds its parseable-length bound")
        if type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY:
            raise ValueError("salsa output capacity is out of range")
        if type(output_is_null) is not bool or type(input_is_null) is not bool:
            raise ValueError("salsa null-pointer probe flag is invalid")
        if output_is_null and input_is_null:
            raise ValueError("salsa input and output cannot both be null")
        result, output = salsa_oracle(values, capacity, output_is_null, input_is_null)
        if result >= 0:
            if result != MAX_OUTPUT_BYTES or len(output) != MAX_OUTPUT_BYTES:
                raise ValueError("salsa success output must contain exactly 64 bytes")
        elif result not in (INVALID_RESULT, OUTPUT_ERROR_RESULT) or output:
            raise ValueError("salsa errors must not write output")
        key = (values, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("salsa probe collides with a distinct output call")
        cases[key] = result, output
        if input_is_null:
            null_input_record_cases.add((values, capacity))

    null_input_record_cases: set[tuple[tuple[int, ...], int]] = set()
    null_input_record_values = (0,)
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        input_length = case.get("input_length", len(values))
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("workspace_bytes", case.get("output_capacity", default_capacity))
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or type(capacity) is not int):
            raise ValueError(f"salsa workload call metadata is invalid: {case['id']}")
        if input_is_null:
            if values or input_length != 1 or output_is_null:
                raise ValueError(f"salsa null-input framing is invalid: {case['id']}")
            record_values = null_input_record_values
        else:
            if input_length != len(values):
                raise ValueError(f"salsa input length mismatch: {case['id']}")
            if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
                raise ValueError(f"salsa input slot is outside signed-i32 range: {case['id']}")
            record_values = values
        result, output = salsa_oracle(values, capacity, output_is_null, input_is_null)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"salsa workload mismatch: {case['id']}")
        add(record_values, capacity, output_is_null, input_is_null)

    vector_values = tuple(vector["input_values"])
    for capacity in (0, MAX_OUTPUT_BYTES - 1, MAX_OUTPUT_BYTES):
        add(vector_values, capacity)
    add(vector_values, default_capacity, output_is_null=True)
    # Invalid frames must be rejected before the null-output pointer or short capacity.
    truncated = (0,) * (MAX_VALID_INPUT_LENGTH - 1)
    add(truncated, 0)
    add(truncated, default_capacity)
    add(truncated, 0, output_is_null=True)
    add(truncated, default_capacity, output_is_null=True)

    rng = random.Random(20261017)
    for index in range(128):
        values = tuple(rng.randint(I32_MIN, I32_MAX) for _ in range(MAX_VALID_INPUT_LENGTH))
        for capacity in (0, MAX_OUTPUT_BYTES - 1, MAX_OUTPUT_BYTES):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    malformed = ((), (0,), (0,) * 15, (0,) * MAX_PARSEABLE_INPUT_LENGTH)
    for values in malformed:
        add(tuple(values))

    records = []
    for (values, capacity, output_is_null, input_is_null), (result, output) in sorted(cases.items()):
        records.append((values, result, output, capacity, output_is_null, input_is_null))
    lines = [str(len(records)) + "\n"]
    for values, result, output, capacity, output_is_null, input_is_null in records:
        encoded = output.hex() if output else "-"
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)} {capacity} "
                     f"{int(input_is_null)} {int(output_is_null)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def sjt_corpus(workload: dict) -> tuple[str, int]:
    source = {
        "repository": "TheAlgorithms/Rust",
        "commit": "fed66cb0c74a939ec5163648458a8c2b46fd4c",
        "path": "src/general/permutations/steinhaus_johnson_trotter.rs",
        "symbol": "steinhaus_johnson_trotter_permute",
        "url": "https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/general/permutations/steinhaus_johnson_trotter.rs",
    }
    required_case_ids = {
        "one_value", "three_distinct_values_in_source_order", "repeated_values_keep_indexed_duplicates",
        "signed_extremes", "maximum_six_value_output", "empty_input", "too_many_values",
        "null_input", "null_output", "short_output_capacity",
    }
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    case_ids = [case.get("id") for case in workload.get("cases", [])]
    null_input_workload_cases = [case for case in workload.get("cases", [])
                                 if case.get("input_is_null", False)]
    null_output_workload_cases = [case for case in workload.get("cases", [])
                                  if case.get("output_is_null", False)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-rust-steinhaus-johnson-trotter-i32-v1"
            or workload.get("algorithm") != "steinhaus_johnson_trotter"
            or workload.get("function_symbol") != "steinhaus_johnson_trotter"
            or workload.get("pinned_source") != source
            or input_spec != {
                "kind": "signed_i32_array",
                "encoding": "values to permute; each signed i32 is treated as an indexed value",
                "length_range": [SJT_MIN_LENGTH, SJT_MAX_LENGTH],
                "maximum_valid_array_length": SJT_MAX_LENGTH,
                "maximum_parseable_array_length": SJT_MAX_PARSEABLE_INPUT_LENGTH,
                "invalid_input_result": SJT_INVALID_RESULT,
                "null_input_result": SJT_INVALID_RESULT,
            }
            or output_spec != {
                "kind": "little_endian_signed_i32_array",
                "encoding": "n! rows of n values, flattened row-major; duplicate-valued rows are retained",
                "byte_length_expression": "4 * n! * n",
                "maximum_output_bytes": SJT_MAX_OUTPUT_BYTES,
                "success_result": "output byte length",
                "invalid_input_result": SJT_INVALID_RESULT,
                "null_output_result": SJT_OUTPUT_ERROR_RESULT,
                "insufficient_output_capacity_result": SJT_OUTPUT_ERROR_RESULT,
                "no_write_on_error": True,
            }
            or workload.get("workspace") != {
                "bytes": SJT_MAX_OUTPUT_BYTES,
                "meaning": "Maximum output for six indexed values.",
            }
            or workload.get("measurement") != {
                "comparison_model": "i32_array_bytes_output_call",
                "sample_count": 6,
                "warmup_rounds": 1,
                "repetitions_per_sample": 50,
            }
            or SJT_MIN_LENGTH != 1 or SJT_MAX_LENGTH != 6
            or SJT_MAX_PARSEABLE_INPUT_LENGTH != 7
            or SJT_MAX_OUTPUT_BYTES != 17280
            or SJT_INVALID_RESULT != -1 or SJT_OUTPUT_ERROR_RESULT != -2
            or len(case_ids) != len(required_case_ids)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != required_case_ids
            or len(null_input_workload_cases) != 1
            or null_input_workload_cases[0].get("id") != "null_input"
            or null_input_workload_cases[0].get("input_values") != []
            or null_input_workload_cases[0].get("input_length") != 1
            or null_input_workload_cases[0].get("expected_result") != SJT_INVALID_RESULT
            or len(null_output_workload_cases) != 1
            or null_output_workload_cases[0].get("id") != "null_output"
            or null_output_workload_cases[0].get("expected_result") != SJT_OUTPUT_ERROR_RESULT
            or any(case.get("input_length", len(case.get("input_values", ())))
                   != len(case.get("input_values", ()))
                   for case in workload.get("cases", [])
                   if not case.get("input_is_null", False))):
        raise ValueError("steinhaus_johnson_trotter workload metadata does not match its reviewed i32 contract")

    readme = (ROOT / "benchmarks" / "s" / "steinhaus_johnson_trotter" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "non-adjacent" not in readme
            or "duplicate-valued inputs produce duplicate rows" not in readme):
        raise ValueError("steinhaus_johnson_trotter README is missing its pinned source or semantics caveat")

    maximum_case = next(case for case in workload["cases"]
                        if case.get("id") == "maximum_six_value_output")
    if (len(maximum_case.get("input_values", ())) != SJT_MAX_LENGTH
            or maximum_case.get("expected_result") != SJT_MAX_OUTPUT_BYTES
            or len(maximum_case.get("expected_output_hex", "")) != 2 * SJT_MAX_OUTPUT_BYTES):
        raise ValueError("steinhaus_johnson_trotter is missing its maximum-size output fixture")
    short_capacity_case = next(case for case in workload["cases"]
                               if case.get("id") == "short_output_capacity")
    if (short_capacity_case.get("output_capacity") != 15
            or short_capacity_case.get("expected_result") != SJT_OUTPUT_ERROR_RESULT):
        raise ValueError("steinhaus_johnson_trotter is missing short-capacity coverage")

    default_capacity = SJT_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, bool, bool], tuple[int, bytes]] = {}
    null_input_record_values = (0,)

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False) -> None:
        if len(values) > SJT_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("steinhaus_johnson_trotter input exceeds its parseable-length bound")
        if type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY:
            raise ValueError("steinhaus_johnson_trotter output capacity is out of range")
        if type(output_is_null) is not bool or type(input_is_null) is not bool:
            raise ValueError("steinhaus_johnson_trotter null-pointer probe flag is invalid")
        if output_is_null and input_is_null:
            raise ValueError("steinhaus_johnson_trotter input and output cannot both be null")
        result, output = sjt_oracle(values, capacity, output_is_null, input_is_null)
        if result >= 0:
            if result != len(output) or result > SJT_MAX_OUTPUT_BYTES or result % 4 != 0:
                raise ValueError("steinhaus_johnson_trotter success output violates its byte bound")
        elif result not in (SJT_INVALID_RESULT, SJT_OUTPUT_ERROR_RESULT) or output:
            raise ValueError("steinhaus_johnson_trotter errors must not write output")
        key = (values, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("steinhaus_johnson_trotter probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        input_length = case.get("input_length", len(values))
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("workspace_bytes", case.get("output_capacity", default_capacity))
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or type(capacity) is not int):
            raise ValueError(f"steinhaus_johnson_trotter workload metadata is invalid: {case['id']}")
        if input_is_null:
            if values or input_length != 1 or output_is_null:
                raise ValueError(f"steinhaus_johnson_trotter null-input framing is invalid: {case['id']}")
            record_values = null_input_record_values
        else:
            if input_length != len(values):
                raise ValueError(f"steinhaus_johnson_trotter input length mismatch: {case['id']}")
            if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
                raise ValueError(f"steinhaus_johnson_trotter input slot is outside signed-i32 range: {case['id']}")
            record_values = values
        result, output = sjt_oracle(values, capacity, output_is_null, input_is_null)
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "").lower() != output.hex()):
            raise ValueError(f"steinhaus_johnson_trotter workload mismatch: {case['id']}")
        add(record_values, capacity, output_is_null, input_is_null)

    reference_values = tuple(next(case["input_values"] for case in workload["cases"]
                                  if case.get("id") == "three_distinct_values_in_source_order"))
    reference_result, _ = sjt_oracle(reference_values)
    for capacity in (0, max(0, reference_result - 1), reference_result):
        add(reference_values, capacity)
    add(reference_values, default_capacity, output_is_null=True)
    # Invalid lengths must be rejected before null-output or capacity handling.
    invalid_values = ()
    add(invalid_values, 0)
    add(invalid_values, default_capacity)
    add(invalid_values, 0, output_is_null=True)
    add(invalid_values, default_capacity, output_is_null=True)

    rng = random.Random(20261017)
    for index in range(128):
        count = rng.randint(SJT_MIN_LENGTH, SJT_MAX_LENGTH)
        values = tuple(rng.randint(I32_MIN, I32_MAX) for _ in range(count))
        result, _ = sjt_oracle(values)
        for capacity in (0, max(0, result - 1), result):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    for values in ((), (0,) * SJT_MAX_PARSEABLE_INPUT_LENGTH):
        add(tuple(values))

    records = []
    for (values, capacity, output_is_null, input_is_null), (result, output) in sorted(cases.items()):
        records.append((values, result, output, capacity, output_is_null, input_is_null))
    lines = [str(len(records)) + "\n"]
    for values, result, output, capacity, output_is_null, input_is_null in records:
        encoded = output.hex() if output else "-"
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)} {capacity} "
                     f"{int(input_is_null)} {int(output_is_null)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def kruskal2_corpus(workload: dict) -> tuple[str, int]:
    validate_kruskal2_workload(workload)
    default_capacity = KRUSKAL2_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if len(values) > KRUSKAL2_MAX_INPUT_LENGTH:
            raise ValueError("minimum_spanning_tree_kruskal2 payload exceeds its 194-word bound")
        if (type(input_length) is not int or not 0 <= input_length <= KRUSKAL2_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= KRUSKAL2_MAX_OUTPUT_BYTES):
            raise ValueError("minimum_spanning_tree_kruskal2 input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not KRUSKAL2_I32_MIN <= value <= KRUSKAL2_I32_MAX
                       for value in values)):
            raise ValueError("minimum_spanning_tree_kruskal2 input or pointer framing is invalid")
        result, output = kruskal2_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result > KRUSKAL2_MAX_OUTPUT_BYTES
                    or result < 4 or result % 4 != 0):
                raise ValueError("minimum_spanning_tree_kruskal2 success violates its output bound")
        elif result not in (KRUSKAL2_INVALID_RESULT, KRUSKAL2_OUTPUT_ERROR) or output:
            raise ValueError("minimum_spanning_tree_kruskal2 errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("minimum_spanning_tree_kruskal2 probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum = next(case for case in workload["cases"]
                   if case["id"] == "maximum_input_and_output_64_edges")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = kruskal2_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    one_vertex = (1, 0)
    one_vertex_result, _ = kruskal2_oracle(one_vertex)
    for capacity in (0, one_vertex_result - 1, one_vertex_result):
        add(one_vertex, capacity)
    add(one_vertex, default_capacity, output_is_null=True)

    add((), default_capacity, input_is_null=True, input_length=2)
    disconnected = (3, 1, 0, 1, 1)
    add(disconnected, 0, output_is_null=True)
    add(disconnected, default_capacity)

    rng = random.Random(20261017)
    for index in range(128):
        vertex_count = rng.randint(KRUSKAL2_MIN_VERTEX_COUNT, KRUSKAL2_MAX_VERTEX_COUNT)
        edges: list[tuple[int, int, int]] = []
        seen: set[tuple[int, int]] = set()
        for vertex in range(1, vertex_count):
            parent = rng.randrange(vertex)
            u, v = sorted((parent, vertex))
            weight = rng.choice((KRUSKAL2_I32_MIN, -2, -1, 0, 0, 1, 2, KRUSKAL2_I32_MAX))
            edges.append((u, v, weight))
            seen.add((u, v))
        possible = [(u, v) for u in range(vertex_count) for v in range(u + 1, vertex_count)
                    if (u, v) not in seen]
        extra_count = rng.randint(0, min(KRUSKAL2_MAX_EDGE_COUNT - len(edges), len(possible)))
        for u, v in rng.sample(possible, extra_count):
            weight = rng.choice((KRUSKAL2_I32_MIN, -1, 0, 0, 1, KRUSKAL2_I32_MAX))
            edges.append((u, v, weight))
        rng.shuffle(edges)
        values = (vertex_count, len(edges), *(value for edge in edges for value in edge))
        result, _ = kruskal2_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    records = []
    for (values, input_length, capacity, output_is_null, input_is_null), (result, output) in sorted(cases.items()):
        records.append((values, input_length, result, output, capacity, input_is_null, output_is_null))
    lines = [str(len(records)) + "\n", "separate_input_length\n"]
    for values, input_length, result, output, capacity, input_is_null, output_is_null in records:
        encoded = output.hex() if output else "-"
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {input_length} {result} {len(output)} {capacity} "
                     f"{int(input_is_null)} {int(output_is_null)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def separate_length_corpus(cases: dict) -> tuple[str, int]:
    records = []
    for (values, input_length, capacity, output_is_null, input_is_null), (result, output) in sorted(cases.items()):
        records.append((values, input_length, result, output, capacity, input_is_null, output_is_null))
    lines = [str(len(records)) + "\n", "separate_input_length\n"]
    for values, input_length, result, output, capacity, input_is_null, output_is_null in records:
        encoded = output.hex() if output else "-"
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {input_length} {result} {len(output)} {capacity} "
                     f"{int(input_is_null)} {int(output_is_null)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def scan_scheduling_corpus(workload: dict) -> tuple[str, int]:
    validate_scan_scheduling_workload(workload)
    default_capacity = SCAN_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > SCAN_MAX_INPUT_LENGTH
                or type(input_length) is not int or not 0 <= input_length <= SCAN_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= SCAN_MAX_OUTPUT_BYTES):
            raise ValueError("scan_scheduling input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not SCAN_I32_MIN <= value <= SCAN_I32_MAX
                       for value in values)):
            raise ValueError("scan_scheduling input or pointer framing is invalid")
        result, output = scan_scheduling_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result > SCAN_MAX_OUTPUT_BYTES or result % 4 != 0):
                raise ValueError("scan_scheduling success violates its byte-output bound")
        elif result not in (SCAN_INVALID_RESULT, SCAN_OUTPUT_ERROR) or output:
            raise ValueError("scan_scheduling errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("scan_scheduling probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum = next(case for case in workload["cases"] if case["id"] == "maximum_output_65_values")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = scan_scheduling_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    for values in ((1, 0, 0, 0), (256, 255, 1, 0)):
        result, _ = scan_scheduling_oracle(values)
        for capacity in (0, result if result >= 0 else default_capacity):
            add(values, capacity)
        add(values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=4)

    rng = random.Random(20261017)
    for index in range(128):
        disk_size = rng.randint(SCAN_MIN_DISK_SIZE, SCAN_MAX_DISK_SIZE)
        head_position = rng.randrange(disk_size)
        direction = rng.randrange(2)
        request_count = rng.randint(0, SCAN_MAX_REQUEST_COUNT)
        requests = tuple(rng.randrange(disk_size) for _ in range(request_count))
        values = (disk_size, head_position, direction, request_count, *requests)
        result, _ = scan_scheduling_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def mlfq_corpus(workload: dict) -> tuple[str, int]:
    validate_mlfq_workload(workload)
    default_capacity = MLFQ_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > MLFQ_MAX_INPUT_LENGTH
                or type(input_length) is not int or not 0 <= input_length <= MLFQ_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MLFQ_MAX_OUTPUT_BYTES):
            raise ValueError("multi_level_feedback_queue input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not MLFQ_I32_MIN <= value <= MLFQ_I32_MAX
                       for value in values)):
            raise ValueError("multi_level_feedback_queue input or pointer framing is invalid")
        result, output = mlfq_oracle(values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result < 4 or result > MLFQ_MAX_OUTPUT_BYTES or result % 4 != 0):
                raise ValueError("multi_level_feedback_queue success violates its byte-output bound")
        elif result not in (MLFQ_INVALID_RESULT, MLFQ_OUTPUT_ERROR) or output:
            raise ValueError("multi_level_feedback_queue errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("multi_level_feedback_queue probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])
    maximum = next(case for case in workload["cases"] if case["id"] == "maximum_input_and_output")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = mlfq_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=2)

    rng = random.Random(20261017)
    for index in range(128):
        queue_count = rng.randint(1, MLFQ_MAX_QUEUE_COUNT)
        process_count = rng.randint(0, MLFQ_MAX_PROCESS_COUNT)
        time_slices = tuple(rng.randint(1, MLFQ_MAX_TIME_SLICE)
                            for _ in range(queue_count - 1))
        bursts = tuple(rng.randint(1, MLFQ_MAX_BURST_TIME)
                       for _ in range(process_count))
        values = (queue_count, process_count, *time_slices, *bursts)
        result, _ = mlfq_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def preemptive_corpus(workload: dict) -> tuple[str, int]:
    validate_preemptive_workload(workload)
    default_capacity = PREEMPTIVE_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > PREEMPTIVE_MAX_INPUT_LENGTH
                or type(input_length) is not int or not 0 <= input_length <= PREEMPTIVE_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= PREEMPTIVE_MAX_OUTPUT_BYTES):
            raise ValueError("preemptive_priority_scheduling input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not PREEMPTIVE_I32_MIN <= value <= PREEMPTIVE_I32_MAX
                       for value in values)):
            raise ValueError("preemptive_priority_scheduling input or pointer framing is invalid")
        result, output = preemptive_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result < 4 or result > PREEMPTIVE_MAX_OUTPUT_BYTES or result % 4 != 0):
                raise ValueError("preemptive_priority_scheduling success violates its byte-output bound")
        elif result not in (PREEMPTIVE_INVALID_RESULT, PREEMPTIVE_OUTPUT_ERROR) or output:
            raise ValueError("preemptive_priority_scheduling errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("preemptive_priority_scheduling probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])
    maximum = next(case for case in workload["cases"] if case["id"] == "maximum_80_ticks")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = preemptive_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    for index in range(128):
        process_count = rng.randint(0, PREEMPTIVE_MAX_PROCESS_COUNT)
        process_ids = rng.sample(range(PREEMPTIVE_MAX_PROCESS_ID + 1), process_count)
        processes: list[int] = []
        seen_pairs: set[tuple[int, int]] = set()
        for process_id in process_ids:
            arrival = rng.randint(0, PREEMPTIVE_MAX_ARRIVAL_TIME)
            while True:
                priority = rng.choice((PREEMPTIVE_I32_MIN, PREEMPTIVE_I32_MAX,
                                       rng.randint(-8, 8), rng.randint(-8, 8)))
                if (priority, arrival) not in seen_pairs:
                    seen_pairs.add((priority, arrival))
                    break
            burst = rng.randint(1, PREEMPTIVE_MAX_BURST_TIME)
            processes.extend((process_id, arrival, burst, priority))
        values = (process_count, *processes)
        result, _ = preemptive_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def multikey_corpus(workload: dict) -> tuple[str, int]:
    validate_multikey_workload(workload)
    default_capacity = MULTIKEY_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > MULTIKEY_MAX_INPUT_LENGTH
                or type(input_length) is not int or not 0 <= input_length <= MULTIKEY_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MULTIKEY_MAX_OUTPUT_BYTES):
            raise ValueError("multikey_quick_sort input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not MULTIKEY_I32_MIN <= value <= MULTIKEY_I32_MAX
                       for value in values)):
            raise ValueError("multikey_quick_sort input or pointer framing is invalid")
        result, output = multikey_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result < 4 or result > MULTIKEY_MAX_OUTPUT_BYTES
                    or result % 4 != 0):
                raise ValueError("multikey_quick_sort success violates its byte-output bound")
        elif result not in (MULTIKEY_INVALID_RESULT, MULTIKEY_OUTPUT_ERROR) or output:
            raise ValueError("multikey_quick_sort errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("multikey_quick_sort probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum = next(case for case in workload["cases"]
                   if case["id"] == "maximum_input_and_output")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = multikey_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    for index in range(128):
        string_count = rng.randint(0, MULTIKEY_MAX_STRING_COUNT)
        values = [string_count]
        for _ in range(string_count):
            length = rng.randint(0, MULTIKEY_MAX_STRING_LENGTH)
            values.append(length)
            values.extend(rng.randint(MULTIKEY_MIN_BYTE, MULTIKEY_MAX_BYTE)
                          for _ in range(length))
        packed = tuple(values)
        result, _ = multikey_oracle(packed)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(packed, capacity)
        if index % 16 == 0:
            add(packed, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def max_pooling_corpus(workload: dict) -> tuple[str, int]:
    validate_max_pooling_workload(workload)
    default_capacity = MAX_POOLING_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > MAX_POOLING_MAX_INPUT_LENGTH
                or type(input_length) is not int or not 0 <= input_length <= MAX_POOLING_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_POOLING_MAX_OUTPUT_BYTES):
            raise ValueError("max_pooling input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not MAX_POOLING_I32_MIN <= value <= MAX_POOLING_I32_MAX
                       for value in values)):
            raise ValueError("max_pooling input or pointer framing is invalid")
        result, output = max_pooling_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if result != len(output) or result < 8 or result > MAX_POOLING_MAX_OUTPUT_BYTES or result % 8 != 0:
                raise ValueError("max_pooling success violates its f64 byte-output bound")
        elif result not in (MAX_POOLING_INVALID_RESULT, MAX_POOLING_OUTPUT_ERROR) or output:
            raise ValueError("max_pooling errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("max_pooling probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])
    maximum = next(case for case in workload["cases"]
                   if case["id"] == "maximum_output_size_one_by_one_windows")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = max_pooling_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=3)

    rng = random.Random(20261017)
    for index in range(128):
        matrix_size = rng.randint(MAX_POOLING_MIN_MATRIX_SIZE, MAX_POOLING_MAX_MATRIX_SIZE)
        pool_size = rng.randint(MAX_POOLING_MIN_POOL_SIZE, matrix_size)
        stride = rng.randint(MAX_POOLING_MIN_STRIDE, MAX_POOLING_MAX_STRIDE)
        values = (matrix_size, pool_size, stride, *(
            rng.randint(MAX_POOLING_MIN_PIXEL, MAX_POOLING_MAX_PIXEL)
            for _ in range(matrix_size * matrix_size)))
        result, _ = max_pooling_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def rat_maze_corpus(workload: dict) -> tuple[str, int]:
    validate_rat_maze_workload(workload)
    default_capacity = RAT_MAZE_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > RAT_MAZE_MAX_INPUT_LENGTH
                or type(input_length) is not int or not 0 <= input_length <= RAT_MAZE_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= RAT_MAZE_MAX_OUTPUT_BYTES):
            raise ValueError("rat_maze input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not RAT_MAZE_I32_MIN <= value <= RAT_MAZE_I32_MAX
                       for value in values)):
            raise ValueError("rat_maze input or pointer framing is invalid")
        result, output = rat_maze_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result < 4 or result > RAT_MAZE_MAX_OUTPUT_BYTES
                    or result % 4 != 0):
                raise ValueError("rat_maze success violates its byte-output bound")
        elif result not in (RAT_MAZE_INVALID_RESULT, RAT_MAZE_OUTPUT_ERROR) or output:
            raise ValueError("rat_maze errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("rat_maze probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum = next(case for case in workload["cases"]
                   if case["id"] == "maximum_eight_by_eight_open_maze")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = rat_maze_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    for index in range(128):
        size = rng.randint(RAT_MAZE_MIN_SIZE, RAT_MAZE_MAX_SIZE)
        values = (size, 1, *(rng.randint(0, 1) for _ in range(size * size - 1)))
        result, _ = rat_maze_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    malformed = (
        (), (0,), (RAT_MAZE_MAX_SIZE + 1,), (1,), (1, 0), (1, 2),
        (2, 1, 1, 1), (2, 1, 1, 1, 1, 0),
        (1, 1, RAT_MAZE_I32_MIN),
        tuple([RAT_MAZE_MAX_SIZE] + [1] * RAT_MAZE_MAX_VALID_INPUT_LENGTH),
    )
    for values in malformed:
        add(values)
    add((1, 1), default_capacity, input_length=1)
    return separate_length_corpus(cases)


def minimum_spanning_tree_prims_corpus(workload: dict) -> tuple[str, int]:
    validate_minimum_spanning_tree_prims_workload(workload)
    default_capacity = PRIMS_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > PRIMS_MAX_PARSEABLE_INPUT_LENGTH
                or type(input_length) is not int
                or not 0 <= input_length <= PRIMS_MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= PRIMS_MAX_OUTPUT_BYTES):
            raise ValueError("minimum_spanning_tree_prims input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not PRIMS_I32_MIN <= value <= PRIMS_I32_MAX
                       for value in values)):
            raise ValueError("minimum_spanning_tree_prims input or pointer framing is invalid")
        result, output = prims_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if result != len(output) or result < 4 or result > PRIMS_MAX_OUTPUT_BYTES or result % 4 != 0:
                raise ValueError("minimum_spanning_tree_prims success violates its byte-output bound")
        elif result not in (PRIMS_INVALID_RESULT, PRIMS_OUTPUT_ERROR) or output:
            raise ValueError("minimum_spanning_tree_prims errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("minimum_spanning_tree_prims probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum = next(case for case in workload["cases"]
                   if case["id"] == "maximum_input_and_output_64_edges")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = prims_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=2)

    rng = random.Random(20261017)
    boundary_weights = (PRIMS_I32_MIN, PRIMS_I32_MAX, -1, 0, 1)
    for index in range(128):
        vertex_count = rng.randint(PRIMS_MIN_VERTEX_COUNT, PRIMS_MAX_VERTEX_COUNT)
        edge_set = {(rng.randrange(vertex), vertex) for vertex in range(1, vertex_count)}
        possible_edges = [(left, right) for left in range(vertex_count)
                          for right in range(left + 1, vertex_count)
                          if (left, right) not in edge_set]
        rng.shuffle(possible_edges)
        extra_limit = min(PRIMS_MAX_EDGE_COUNT - len(edge_set), len(possible_edges))
        extra_count = rng.randint(0, extra_limit)
        edge_set.update(possible_edges[:extra_count])
        edges = [(left, right,
                  rng.choice(boundary_weights + (rng.randint(-1000, 1000),)))
                 for left, right in edge_set]
        rng.shuffle(edges)
        values = (vertex_count, len(edges), *(word for edge in edges for word in edge))
        result, _ = prims_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    malformed = (
        (), (0, 0), (PRIMS_MAX_VERTEX_COUNT + 1, 0), (1,), (2, 0),
        (2, 1, 0, 1), (2, 0, 0), (2, 1, 0, 0, 1),
        (2, 1, 1, 0, 1), (2, 1, 0, 2, 1),
        (3, 3, 0, 1, 1, 0, 2, 1, 0, 1, 2),
        (1, 1, 0, 0, 1), (2, -1),
    )
    for values in malformed:
        add(values)
    add((1, 0), default_capacity, input_length=1)
    return separate_length_corpus(cases)


def mo_corpus(workload: dict) -> tuple[str, int]:
    validate_mo_workload(workload)
    default_capacity = MO_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > MO_MAX_INPUT_LENGTH
                or type(input_length) is not int
                or not 0 <= input_length <= MO_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError("mo input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not MO_I32_MIN <= value <= MO_I32_MAX
                       for value in values)):
            raise ValueError("mo input or pointer framing is invalid")
        result, output = mo_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            # q=0 succeeds with zero bytes when the output pointer is non-null.
            if (result != len(output) or result > MO_MAX_OUTPUT_BYTES or result % 4 != 0):
                raise ValueError("mo success violates its byte-output bound")
        elif result not in (MO_INVALID_RESULT, MO_OUTPUT_ERROR) or output:
            raise ValueError("mo errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("mo probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum = next(case for case in workload["cases"]
                   if case["id"] == "maximum_n_queries_and_output")
    maximum_values = tuple(maximum["input_values"])
    maximum_result, _ = mo_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add(maximum_values, MAX_OUTPUT_CAPACITY)
    add((), 0, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    for index in range(128):
        array_size = rng.randint(MO_MIN_ARRAY_SIZE, MO_MAX_ARRAY_SIZE)
        values = tuple(rng.randint(MO_MIN_VALUE, MO_MAX_VALUE) for _ in range(array_size))
        query_count = rng.randint(MO_MIN_QUERY_COUNT, MO_MAX_QUERY_COUNT)
        queries = []
        for _ in range(query_count):
            left = rng.randint(1, array_size)
            right = rng.randint(left, array_size)
            queries.extend((left, right))
        packed = (array_size, *values, query_count, *queries)
        result, _ = mo_oracle(packed)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(packed, capacity)
        if index % 16 == 0:
            # This deliberately checks the null-output error for both empty and nonempty answers.
            add(packed, 0 if query_count == 0 else default_capacity, output_is_null=True)

    maximum_parseable_trailing_word = (
        MO_MAX_ARRAY_SIZE,
        *(index % (MO_MAX_VALUE + 1) for index in range(MO_MAX_ARRAY_SIZE)),
        MO_MAX_QUERY_COUNT,
        *((1, 1) * MO_MAX_QUERY_COUNT),
        0,
    )
    malformed = (
        (), (0,), (MO_MAX_ARRAY_SIZE + 1,), (1,), (1, 0), (1, 0, 1),
        (1, 0, 1, 0, 1), (1, 0, 1, 1, 0), (1, MO_I32_MIN, 0),
        (1, MO_MAX_VALUE + 1, 0), (1, 0, MO_MAX_QUERY_COUNT + 1),
        (1, 0, 0, 7), maximum_parseable_trailing_word,
    )
    for values in malformed:
        add(values)
    add((1, 0, 0), default_capacity, input_length=2)
    add((1, 0, 0), default_capacity, input_length=4)
    add((), default_capacity, input_is_null=True, input_length=1)
    add((1, 0, 1, 1, 1), 0, output_is_null=True)
    add((1, 0, 1, 1, 1), MAX_OUTPUT_CAPACITY)
    return separate_length_corpus(cases)


def hungarian_algorithm_corpus(workload: dict) -> tuple[str, int]:
    validate_hungarian_algorithm_workload(workload)
    default_capacity = HUNGARIAN_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > HUNGARIAN_MAX_INPUT_LENGTH
                or type(input_length) is not int
                or not 0 <= input_length <= HUNGARIAN_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError("hungarian_algorithm input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or any(type(value) is not int or not HUNGARIAN_I32_MIN <= value <= HUNGARIAN_I32_MAX
                       for value in values)):
            raise ValueError("hungarian_algorithm input or pointer framing is invalid")
        result, output = hungarian_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result > HUNGARIAN_MAX_OUTPUT_BYTES or result % 4 != 0):
                raise ValueError("hungarian_algorithm success violates its byte-output bound")
        elif result not in (HUNGARIAN_INVALID_RESULT, HUNGARIAN_OUTPUT_ERROR) or output:
            raise ValueError("hungarian_algorithm errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("hungarian_algorithm probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case["output_is_null"], case["input_is_null"], case["input_length"])

    maximum_values = (HUNGARIAN_MAX_DIMENSION, HUNGARIAN_MAX_DIMENSION,
                     *([HUNGARIAN_MAX_COST] * HUNGARIAN_MAX_DIMENSION ** 2))
    maximum_result, _ = hungarian_oracle(maximum_values)
    for capacity in (0, maximum_result - 1, maximum_result, default_capacity, MAX_OUTPUT_CAPACITY):
        add(maximum_values, capacity)
    add(maximum_values, default_capacity, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    for index in range(128):
        rows = rng.randint(1, HUNGARIAN_MAX_DIMENSION)
        cols = rng.randint(1, HUNGARIAN_MAX_DIMENSION)
        costs = tuple(rng.choice((0, 1, HUNGARIAN_MAX_COST,
                                  rng.randint(0, HUNGARIAN_MAX_COST)))
                      for _ in range(rows * cols))
        values = (rows, cols, *costs)
        result, _ = hungarian_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0:
            add(values, default_capacity, output_is_null=True)

    maximum_parseable_trailing_word = (
        HUNGARIAN_MAX_DIMENSION, HUNGARIAN_MAX_DIMENSION,
        *([0] * (HUNGARIAN_MAX_DIMENSION ** 2)), 0,
    )
    malformed = (
        (), (1,), (0, 1), (HUNGARIAN_MAX_DIMENSION + 1, 1),
        (1, 0), (1, 1), (1, 1, -1), (1, 1, HUNGARIAN_MAX_COST + 1),
        (1, 1, 0, 0), maximum_parseable_trailing_word,
        (HUNGARIAN_I32_MIN, 1), (1, HUNGARIAN_I32_MAX),
    )
    for values in malformed:
        add(values)
    add((1, 1, 0), default_capacity, input_length=2)
    add((1, 1, 0), default_capacity, input_length=4)
    add((1, 1, 0), 0, output_is_null=True)
    return separate_length_corpus(cases)


def merge_sort_no_extra_space_corpus(workload: dict) -> tuple[str, int]:
    validate_merge_sort_no_extra_space_workload(workload)
    default_capacity = MERGE_SORT_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > MERGE_SORT_MAX_PARSEABLE_LENGTH
                or type(input_length) is not int
                or not 0 <= input_length <= MERGE_SORT_MAX_PARSEABLE_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError("merge_sort_no_extra_space input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or input_is_null and (values or input_length == 0)
                or not input_is_null and input_length != len(values)
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)):
            raise ValueError("merge_sort_no_extra_space input or pointer framing is invalid")
        result, output = merge_sort_no_extra_space_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        if result >= 0:
            if (result != len(output) or result > MERGE_SORT_MAX_OUTPUT_BYTES or result % 4 != 0):
                raise ValueError("merge_sort_no_extra_space success violates its byte-output bound")
        elif result not in (MERGE_SORT_INVALID_RESULT, MERGE_SORT_OUTPUT_ERROR) or output:
            raise ValueError("merge_sort_no_extra_space errors must not write output")
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("merge_sort_no_extra_space probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case.get("output_is_null", False), case.get("input_is_null", False),
            case["input_length"])

    empty_values: tuple[int, ...] = ()
    add(empty_values, 0)
    add(empty_values, default_capacity)
    add(empty_values, MAX_OUTPUT_CAPACITY)
    add(empty_values, 0, output_is_null=True)

    sample_values = (MERGE_SORT_MAX_VALUE, 0, 1, 1, 32766, 32767, 0)
    sample_result, _ = merge_sort_no_extra_space_oracle(sample_values)
    for capacity in (0, sample_result - 1, sample_result,
                     default_capacity, MAX_OUTPUT_CAPACITY):
        add(sample_values, capacity)
    add(sample_values, default_capacity, output_is_null=True)
    add((-1,), 0, output_is_null=True)
    add((MERGE_SORT_MAX_VALUE + 1,), 0, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    boundary_values = (MERGE_SORT_MIN_VALUE, 1, MERGE_SORT_MAX_VALUE - 1, MERGE_SORT_MAX_VALUE)
    for index in range(128):
        length = rng.randint(0, MERGE_SORT_MAX_LENGTH)
        values = tuple(rng.choice(boundary_values + (rng.randint(
            MERGE_SORT_MIN_VALUE, MERGE_SORT_MAX_VALUE),)) for _ in range(length))
        result, _ = merge_sort_no_extra_space_oracle(values)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0 and length:
            add(values, default_capacity, output_is_null=True)

    malformed = (
        (MERGE_SORT_MAX_VALUE + 1,), (-1,), (I32_MIN,), (I32_MAX,),
        tuple([MERGE_SORT_MIN_VALUE] * MERGE_SORT_MAX_PARSEABLE_LENGTH),
    )
    for values in malformed:
        add(values)
    add((-1,), 0, output_is_null=True)
    return separate_length_corpus(cases)


def reverse_singly_linked_list_corpus(workload: dict) -> tuple[str, int]:
    validate_reverse_singly_linked_list_workload(workload)
    default_capacity = REVERSE_LIST_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > REVERSE_LIST_MAX_PARSEABLE_LENGTH
                or type(input_length) is not int
                or not 0 <= input_length <= REVERSE_LIST_MAX_PARSEABLE_LENGTH
                or type(capacity) is not int
                or not 0 <= capacity <= REVERSE_LIST_MAX_OUTPUT_BYTES):
            raise ValueError("reverse_singly_linked_list input length or output capacity is out of range")
        if (type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or input_is_null and values
                or not input_is_null and input_length > len(values)
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)):
            raise ValueError("reverse_singly_linked_list input or pointer framing is invalid")

        if input_is_null or input_length > REVERSE_LIST_MAX_LENGTH:
            result, output = REVERSE_LIST_INVALID_RESULT, b""
        else:
            selected = values[:input_length]
            output = struct.pack("<" + "i" * len(selected), *reversed(selected))
            if output_is_null or capacity < len(output):
                result, output = REVERSE_LIST_OUTPUT_ERROR, b""
            else:
                result = len(output)
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("reverse_singly_linked_list probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case.get("output_is_null", False), case.get("input_is_null", False),
            case["input_length"])

    add((), 0)
    add((), default_capacity)
    add((), 0, output_is_null=True)
    add((17, -4, 29), input_length=2)
    add((17, -4, 29), input_length=0)

    full_values = tuple(range(-128, 128))
    for capacity in (0, REVERSE_LIST_MAX_OUTPUT_BYTES - 1, REVERSE_LIST_MAX_OUTPUT_BYTES):
        add(full_values, capacity)
    add(full_values, default_capacity, output_is_null=True)
    over_domain = tuple([0] * REVERSE_LIST_MAX_PARSEABLE_LENGTH)
    add(over_domain, 0)
    add(over_domain, 0, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=0)
    add((), default_capacity, input_is_null=True, input_length=1)

    rng = random.Random(20261017)
    boundary_values = (I32_MIN, -1, 0, 1, I32_MAX)
    for index in range(128):
        length = rng.randint(0, REVERSE_LIST_MAX_LENGTH)
        values = tuple(rng.choice(boundary_values + (rng.randint(I32_MIN, I32_MAX),))
                       for _ in range(length))
        output_bytes = length * 4
        for capacity in (0, max(0, output_bytes - 1), output_bytes, default_capacity):
            add(values, capacity)
        if index % 16 == 0 and length:
            add(values, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def snail_corpus(workload: dict) -> tuple[str, int]:
    validate_snail_workload(workload)
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def reference(values: tuple[int, ...], input_length: int, capacity: int,
                  output_is_null: bool, input_is_null: bool) -> tuple[int, bytes]:
        if input_is_null or input_length != len(values):
            return SNAIL_INVALID_RESULT, b""
        if (not 2 <= len(values) <= SNAIL_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)):
            return SNAIL_INVALID_RESULT, b""
        rows, columns = values[:2]
        if (not 0 <= rows <= SNAIL_MAX_ROWS
                or not 0 <= columns <= SNAIL_MAX_COLUMNS
                or rows == 0 and columns != 0
                or columns == 1 and rows != 1
                or len(values) != 2 + rows * columns):
            return SNAIL_INVALID_RESULT, b""

        ordered: list[int] = []
        if rows and columns:
            visited: set[tuple[int, int]] = set()
            row, column, direction = 0, 0, 0
            directions = ((0, 1), (1, 0), (0, -1), (-1, 0))
            while len(visited) < rows * columns:
                visited.add((row, column))
                ordered.append(values[2 + row * columns + column])
                if len(visited) == rows * columns:
                    break
                for _ in range(4):
                    delta_row, delta_column = directions[direction]
                    next_row, next_column = row + delta_row, column + delta_column
                    if (0 <= next_row < rows and 0 <= next_column < columns
                            and (next_row, next_column) not in visited):
                        row, column = next_row, next_column
                        break
                    direction = (direction + 1) % 4

        output = struct.pack("<" + "i" * len(ordered), *ordered) if ordered else b""
        if output_is_null or capacity < len(output):
            return SNAIL_OUTPUT_ERROR, b""
        return len(output), output

    def add(values: tuple[int, ...], capacity: int = SNAIL_MAX_OUTPUT_BYTES,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > SNAIL_MAX_PARSEABLE_INPUT_LENGTH
                or type(input_length) is not int
                or not 0 <= input_length <= SNAIL_MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int
                or not 0 <= capacity <= SNAIL_MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool or type(input_is_null) is not bool
                or input_is_null and output_is_null
                or input_is_null and values
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)):
            raise ValueError("snail corpus input or pointer framing is invalid")
        result, output = reference(values, input_length, capacity, output_is_null, input_is_null)
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("snail probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["output_capacity"],
            case.get("output_is_null", False), case.get("input_is_null", False),
            case["input_length"])

    add((), 0, input_length=0)
    add((), SNAIL_MAX_OUTPUT_BYTES, input_length=2)
    add((0, 0), 0)
    add((4, 0), 0)
    add((1, 4, 11, -7, 23, 5), 0)
    add((1, 4, 11, -7, 23, 5), 15)
    add((1, 4, 11, -7, 23, 5), 16)
    add((1, 4, 11, -7, 23, 5), 16, output_is_null=True)
    add((0, 1), 0, output_is_null=True)
    add((2, 1, 11, 22), 0)
    add((2, 1, 11, 22), 0, output_is_null=True)
    add((1, 1, 42, 0), 0)
    add((1, 1, 42), 0, input_length=2)
    add((SNAIL_MAX_ROWS, SNAIL_MAX_COLUMNS, *range(
        SNAIL_MAX_ROWS * SNAIL_MAX_COLUMNS), 99), 0)
    add((), SNAIL_MAX_OUTPUT_BYTES, input_is_null=True, input_length=0)
    add((), SNAIL_MAX_OUTPUT_BYTES, input_is_null=True, input_length=2)

    rng = random.Random(20261017)
    boundary_values = (I32_MIN, -1, 0, 1, I32_MAX)
    for index in range(128):
        rows = rng.randint(0, SNAIL_MAX_ROWS)
        if rows == 0:
            columns = 0
        else:
            columns = rng.randint(0, SNAIL_MAX_COLUMNS)
            if columns == 1 and rows > 1:
                columns = 2
        cells = tuple(rng.choice(boundary_values + (rng.randint(I32_MIN, I32_MAX),))
                      for _ in range(rows * columns))
        values = (rows, columns) + cells
        required = 4 * len(cells)
        for capacity in (0, max(0, required - 1), required, SNAIL_MAX_OUTPUT_BYTES):
            add(values, capacity)
        if index % 16 == 0 and required:
            add(values, SNAIL_MAX_OUTPUT_BYTES, output_is_null=True)

    return separate_length_corpus(cases)


def reverse_kgroup_corpus(workload: dict) -> tuple[str, int]:
    validate_reverse_kgroup_workload(workload)
    default_capacity = REVERSE_KGROUP_MAX_OUTPUT_BYTES
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def reference(values: tuple[int, ...], input_length: int, capacity: int,
                  output_is_null: bool, input_is_null: bool) -> tuple[int, bytes]:
        if input_is_null or input_length != len(values):
            return REVERSE_KGROUP_INVALID_RESULT, b""
        if (not 1 <= len(values) <= REVERSE_KGROUP_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)
                or len(values) > REVERSE_KGROUP_MAX_VALID_INPUT_LENGTH):
            return REVERSE_KGROUP_INVALID_RESULT, b""
        group_size = values[0]
        payload = list(values[1:])
        if (not 1 <= group_size <= REVERSE_KGROUP_MAX_LIST_LENGTH
                or len(payload) > REVERSE_KGROUP_MAX_LIST_LENGTH):
            return REVERSE_KGROUP_INVALID_RESULT, b""

        reversed_payload: list[int] = []
        for start in range(0, len(payload), group_size):
            group = payload[start:start + group_size]
            reversed_payload.extend(reversed(group) if len(group) == group_size else group)
        output = (struct.pack("<" + "i" * len(reversed_payload), *reversed_payload)
                  if reversed_payload else b"")
        if output_is_null or capacity < len(output):
            return REVERSE_KGROUP_OUTPUT_ERROR, b""
        return len(output), output

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > REVERSE_KGROUP_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)
                or type(input_length) is not int
                or not 0 <= input_length <= REVERSE_KGROUP_MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int
                or not 0 <= capacity <= REVERSE_KGROUP_MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool or type(input_is_null) is not bool
                or input_is_null and output_is_null
                or input_is_null and values
                or not input_is_null and input_length != len(values)):
            raise ValueError("reverse_kgroup corpus input or pointer framing is invalid")
        result, output = reference(values, input_length, capacity, output_is_null, input_is_null)
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("reverse_kgroup probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]),
            case.get("workspace_bytes", case.get("output_capacity", default_capacity)),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case["input_length"])

    add((), 0, input_length=0)
    add((1,), 0)
    add((256,), default_capacity)
    add((1, -5, 7, I32_MIN, I32_MAX))
    add((2, 10, 20, 30))
    add((3, 1, 2, 3, 4, 5, 6, 7, 8), output_is_null=True)
    add((1,), 0, output_is_null=True)
    add((0,), 0, output_is_null=True)
    add((), default_capacity, input_is_null=True, input_length=0)
    add((), default_capacity, input_is_null=True, input_length=1)

    maximum_values = tuple(range(-128, 128))
    for group_size in (1, 2, 3, 255, 256):
        values = (group_size, *maximum_values)
        result, _ = reference(values, len(values), default_capacity, False, False)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        add(values, default_capacity, output_is_null=True)

    malformed = (
        (), (0,), (-1,), (REVERSE_KGROUP_MAX_LIST_LENGTH + 1,),
        (1, *range(REVERSE_KGROUP_MAX_LIST_LENGTH + 1)),
        (2, 1), (3, 1, 2),
    )
    for values in malformed:
        add(tuple(values))

    rng = random.Random(20261017)
    boundary_values = (I32_MIN, -1, 0, 1, I32_MAX)
    for index in range(128):
        group_size = rng.randint(1, REVERSE_KGROUP_MAX_LIST_LENGTH)
        list_length = rng.randint(0, REVERSE_KGROUP_MAX_LIST_LENGTH)
        payload = tuple(rng.choice(boundary_values + (rng.randint(I32_MIN, I32_MAX),))
                        for _ in range(list_length))
        values = (group_size, *payload)
        result, _ = reference(values, len(values), default_capacity, False, False)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            add(values, capacity)
        if index % 16 == 0 and list_length:
            add(values, default_capacity, output_is_null=True)

    return separate_length_corpus(cases)


def sjfscheduling_corpus(workload: dict) -> tuple[str, int]:
    validate_sjfscheduling_workload(workload)
    default_capacity = 256
    cases: dict[tuple[tuple[int, ...], int, int, bool, bool], tuple[int, bytes]] = {}

    def reference(values: tuple[int, ...], input_length: int, capacity: int,
                  output_is_null: bool, input_is_null: bool) -> tuple[int, bytes]:
        if input_is_null or input_length != len(values):
            return -1, b""
        if (not 1 <= len(values) <= 130
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)):
            return -1, b""
        process_count = values[0]
        if not 0 <= process_count <= 64 or len(values) != 1 + 2 * process_count:
            return -1, b""

        waiting: list[tuple[int, int, int]] = []
        for index in range(process_count):
            arrival, burst = values[1 + 2 * index:3 + 2 * index]
            if not 0 <= arrival <= 255 or not 1 <= burst <= 255:
                return -1, b""
            waiting.append((index, arrival, burst))
        waiting.sort(key=lambda process: process[1])

        current_time = 0
        next_waiting = 0
        ready: list[tuple[int, int, int]] = []
        schedule: list[int] = []
        while len(schedule) < process_count:
            while (next_waiting < process_count
                   and waiting[next_waiting][1] <= current_time):
                ready.append(waiting[next_waiting])
                next_waiting += 1
            if not ready:
                current_time += 1
                continue
            selected_index = min(range(len(ready)), key=lambda index: ready[index][2])
            process_id, _, burst = ready.pop(selected_index)
            schedule.append(process_id)
            current_time += burst

        output = struct.pack("<" + "i" * len(schedule), *schedule) if schedule else b""
        if output_is_null or capacity < len(output):
            return -2, b""
        return len(output), output

    def add(values: tuple[int, ...], capacity: int = default_capacity,
            output_is_null: bool = False, input_is_null: bool = False,
            input_length: int | None = None) -> None:
        if input_length is None:
            input_length = len(values)
        if (len(values) > 130
                or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                       for value in values)
                or type(input_length) is not int or not 0 <= input_length <= 130
                or type(capacity) is not int or not 0 <= capacity <= 256
                or type(output_is_null) is not bool or type(input_is_null) is not bool
                or input_is_null and output_is_null
                or input_is_null and values
                or not input_is_null and input_length != len(values)):
            raise ValueError("sjfscheduling corpus input or pointer framing is invalid")
        result, output = reference(values, input_length, capacity, output_is_null, input_is_null)
        key = (values, input_length, capacity, output_is_null, input_is_null)
        if key in cases and cases[key] != (result, output):
            raise ValueError("sjfscheduling probe collides with a distinct output call")
        cases[key] = result, output

    for case in workload["cases"]:
        add(tuple(case["input_values"]), case.get("output_capacity", default_capacity),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case["input_length"])

    add((0,), 0)
    add((0,), default_capacity, output_is_null=True)
    add((1, 0, 1), 0)
    add((1, 0, 1), 3)
    add((1, 0, 1), 4)
    add((1, 0, 1), default_capacity, output_is_null=True)
    add((1, 0, 0), 0, output_is_null=True)
    add((1, 0, 0), 0)
    add((), default_capacity, input_is_null=True, input_length=0)
    add((), default_capacity, input_is_null=True, input_length=1)

    malformed = (
        (), (2,), (1, 0), (1, 0, 1, 9), (65,), (-1,),
        (1, -1, 1), (1, 256, 1), (1, 0, 0), (1, 0, 256),
        (64, *([0, 1] * 64), 7),
    )
    for values in malformed:
        add(values)

    rng = random.Random(20261017)
    for _ in range(128):
        count = rng.randint(0, 64)
        values = (count, *(cell for _ in range(count)
                           for cell in (rng.randint(0, 255), rng.randint(1, 255))))
        result, _ = reference(values, len(values), default_capacity, False, False)
        for capacity in (0, max(0, result - 1), result, default_capacity):
            if capacity >= 0:
                add(values, capacity)

    return separate_length_corpus(cases)


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    if algorithm == "salsa":
        return salsa_corpus(workload)
    if algorithm == "steinhaus_johnson_trotter":
        return sjt_corpus(workload)
    if algorithm == "minimum_spanning_tree_kruskal2":
        return kruskal2_corpus(workload)
    if algorithm == "scan_scheduling":
        return scan_scheduling_corpus(workload)
    if algorithm == "multi_level_feedback_queue":
        return mlfq_corpus(workload)
    if algorithm == "preemptive_priority_scheduling":
        return preemptive_corpus(workload)
    if algorithm == "multikey_quick_sort":
        return multikey_corpus(workload)
    if algorithm == "max_pooling":
        return max_pooling_corpus(workload)
    if algorithm == "rat_maze":
        return rat_maze_corpus(workload)
    if algorithm == "minimum_spanning_tree_prims":
        return minimum_spanning_tree_prims_corpus(workload)
    if algorithm == "mo":
        return mo_corpus(workload)
    if algorithm == "hungarian_algorithm":
        return hungarian_algorithm_corpus(workload)
    if algorithm == "merge_sort_no_extra_space":
        return merge_sort_no_extra_space_corpus(workload)
    if algorithm == "reverse_singly_linked_list":
        return reverse_singly_linked_list_corpus(workload)
    if algorithm == "snail":
        return snail_corpus(workload)
    if algorithm == "reverse_kgroup":
        return reverse_kgroup_corpus(workload)
    if algorithm == "sjfscheduling":
        return sjfscheduling_corpus(workload)
    raise ValueError(f"no i32 byte-output corpus for {algorithm}")


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i32_array_bytes_output")
    checker = manifest["binaries"]["i32_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"i32 byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks" / "run_i32_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        input_values = case["input_values"]
        input_length = case.get("input_length", len(input_values))
        expected_capacity = case.get("workspace_bytes", case.get(
            "output_capacity", (workload.get("workspace") or {}).get("bytes", 0)))
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != input_length
                or record["workload"]["input_values"] != input_values
                or record["workload"].get("input_is_null", False) != case.get("input_is_null", False)
                or record["workload"]["output_capacity"] != expected_capacity
                or record["workload"]["output_is_null"] != case.get("output_is_null", False)
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["measurement"]["comparison_model"] != "i32_array_bytes_output_call"
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, default="salsa")
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build" / "i32_array_bytes_output")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    algorithm = args.algorithm
    workload_path = (ROOT / "benchmarks" / "m" / "rat_maze" / "workload.json"
                     if algorithm == "rat_maze" else
                     ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload, algorithm)
    (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language, directory / algorithm / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / f"{algorithm}-verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
