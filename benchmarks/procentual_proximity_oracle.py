"""Oracle for the bounded row-scoring portion of scoring_algorithm.py."""

from __future__ import annotations

import struct
from typing import Sequence


MAX_ROWS = 64
MAX_COLUMNS = 8
MIN_VALUE = -10_000
MAX_VALUE = 10_000
MAX_INPUT_LENGTH = 2 + MAX_COLUMNS + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_ROWS * (MAX_COLUMNS + 1) * 8


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the flat row-major float64 rows, each ending in its score."""
    if (
        not isinstance(values, (tuple, list))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""

    row_count, column_count = values[:2]
    if not 1 <= row_count <= MAX_ROWS or not 1 <= column_count <= MAX_COLUMNS:
        return -1, b""
    if len(values) != 2 + column_count + row_count * column_count:
        return -1, b""

    weights = values[2:2 + column_count]
    data_values = values[2 + column_count:]
    if any(weight not in (0, 1) for weight in weights):
        return -1, b""
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in data_values):
        return -1, b""

    # The source first transposes the row-major data into columns, then scores
    # each column independently. Keep its arithmetic order, including the
    # weight-0 subtraction after division, to preserve its binary64 results.
    columns = [
        [float(data_values[row * column_count + column]) for row in range(row_count)]
        for column in range(column_count)
    ]
    column_scores: list[list[float]] = []
    for column, weight in zip(columns, weights):
        minimum = min(column)
        maximum = max(column)
        if maximum == minimum:
            column_scores.append([1.0 if weight == 0 else 0.0] * row_count)
        elif weight == 0:
            column_scores.append([
                1.0 - ((item - minimum) / (maximum - minimum)) for item in column
            ])
        else:
            column_scores.append([
                (item - minimum) / (maximum - minimum) for item in column
            ])

    scores = [0.0] * row_count
    for per_column in column_scores:
        for row, value in enumerate(per_column):
            scores[row] = scores[row] + value

    output = bytearray()
    for row in range(row_count):
        for column in range(column_count):
            output.extend(struct.pack("<d", float(data_values[row * column_count + column])))
        output.extend(struct.pack("<d", scores[row]))

    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), bytes(output)
