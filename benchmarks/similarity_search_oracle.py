"""Bounded fixed-point oracle for TheAlgorithms/Python similarity search."""

from __future__ import annotations

import math
import struct

MAX_ROWS = 32
MAX_QUERIES = 8
MAX_FEATURES = 16
MAX_INPUT_LENGTH = 3 + (MAX_ROWS + MAX_QUERIES) * MAX_FEATURES
MAX_OUTPUT_BYTES = MAX_QUERIES * (16 + 8 * MAX_FEATURES)
COORDINATE_SCALE = 1_000_000
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    """Return the exact per-query record bytes, or an ABI status code."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (
        len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""
    rows, queries, features = values[:3]
    if not 1 <= rows <= MAX_ROWS or not 1 <= queries <= MAX_QUERIES:
        return INVALID_RESULT, b""
    if not 1 <= features <= MAX_FEATURES:
        return INVALID_RESULT, b""
    cells = rows * features
    query_cells = queries * features
    if len(values) != 3 + cells + query_cells:
        return INVALID_RESULT, b""
    dataset_values = values[3 : 3 + cells]
    query_values = values[3 + cells :]
    if any(not -COORDINATE_SCALE <= value <= COORDINATE_SCALE for value in dataset_values):
        return INVALID_RESULT, b""
    if any(not -COORDINATE_SCALE <= value <= COORDINATE_SCALE for value in query_values):
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""

    dataset = [
        dataset_values[row * features : (row + 1) * features]
        for row in range(rows)
    ]
    query_rows = [
        query_values[query * features : (query + 1) * features]
        for query in range(queries)
    ]
    output = bytearray()
    for query in query_rows:
        def distance(candidate: list[int]) -> float:
            total = 0.0
            for candidate_value, query_value in zip(candidate, query):
                delta = candidate_value / COORDINATE_SCALE - query_value / COORDINATE_SCALE
                total += math.pow(delta, 2)
            return math.sqrt(total)

        best_row = 0
        best_distance = distance(dataset[0])
        for row in range(1, rows):
            candidate_distance = distance(dataset[row])
            if best_distance > candidate_distance:
                best_row = row
                best_distance = candidate_distance
        output.extend(struct.pack("<q", best_row))
        output.extend(struct.pack("<d", best_distance))
        for coordinate in dataset[best_row]:
            output.extend(struct.pack("<q", coordinate))

    if output_capacity is not None and output_capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), bytes(output)
