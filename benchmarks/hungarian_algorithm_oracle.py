"""Oracle for the bounded pinned Java Hungarian assignment algorithm."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_DIMENSION = 1
MAX_DIMENSION = 8
MIN_COST = 0
MAX_COST = 1000
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_VALID_INPUT_WORDS = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_INPUT_WORDS = MAX_VALID_INPUT_WORDS
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_WORDS = MAX_DIMENSION + 1
MIN_OUTPUT_BYTES = 2 * 4
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 4
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _hungarian_assignment(cost: list[list[int]]) -> tuple[list[int], int]:
    """Match the pinned source's zero-padding and strict scan tie order."""
    rows = len(cost)
    cols = len(cost[0])
    size = max(rows, cols)
    square = [
        [cost[i][j] if i < rows and j < cols else 0 for j in range(size)]
        for i in range(size)
    ]

    # These 1-indexed potential/matching arrays mirror the source loop order.
    u = [0] * (size + 1)
    v = [0] * (size + 1)
    p = [0] * (size + 1)
    way = [0] * (size + 1)
    for row in range(1, size + 1):
        p[0] = row
        column0 = 0
        min_value = [I32_MAX] * (size + 1)
        used = [False] * (size + 1)
        while True:
            used[column0] = True
            row0 = p[column0]
            delta = I32_MAX
            column1 = 0
            for column in range(1, size + 1):
                if not used[column]:
                    reduced = square[row0 - 1][column - 1] - u[row0] - v[column]
                    if reduced < min_value[column]:
                        min_value[column] = reduced
                        way[column] = column0
                    if min_value[column] < delta:
                        delta = min_value[column]
                        column1 = column
            for column in range(size + 1):
                if used[column]:
                    u[p[column]] += delta
                    v[column] -= delta
                else:
                    min_value[column] -= delta
            column0 = column1
            if p[column0] == 0:
                break
        while True:
            column1 = way[column0]
            p[column0] = p[column1]
            column0 = column1
            if column0 == 0:
                break

    column_for_row = [-1] * size
    for column in range(1, size + 1):
        if p[column] != 0:
            column_for_row[p[column] - 1] = column - 1

    assignment = [-1] * rows
    total = 0
    for row in range(rows):
        column = column_for_row[row]
        if 0 <= column < cols:
            assignment[row] = column
            total += cost[row][column]
    return assignment, total


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return row assignments followed by the minimum total as LE i32 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    rows, cols = values[0], values[1]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if not MIN_DIMENSION <= cols <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if len(values) != 2 + rows * cols:
        return INVALID_RESULT, b""

    flat_costs = values[2:]
    if any(not MIN_COST <= value <= MAX_COST for value in flat_costs):
        return INVALID_RESULT, b""
    cost = [
        list(flat_costs[row * cols : (row + 1) * cols])
        for row in range(rows)
    ]
    assignment, total = _hungarian_assignment(cost)
    result_words = [*assignment, total]
    encoded = struct.pack("<" + "i" * len(result_words), *result_words)

    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Convenience entrypoint used by the benchmark workload tooling."""
    return expected_output(values)
