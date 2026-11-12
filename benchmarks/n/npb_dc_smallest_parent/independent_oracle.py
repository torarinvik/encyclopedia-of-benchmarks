"""Independent verifier: direct raw-row groupings and independent parent selection."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_DIMS = 5
MAX_ROWS = 16
MAX_INPUT_LENGTH = 98


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values):
        return INVALID_RESULT
    dimensions, rows_count = values[0], values[1]
    if dimensions < 1 or dimensions > MAX_DIMS or rows_count < 1 or rows_count > MAX_ROWS:
        return INVALID_RESULT
    if size != 2 + rows_count * (dimensions + 1):
        return INVALID_RESULT

    tuples: list[tuple[int, ...]] = []
    measures: list[int] = []
    cursor = 2
    for _ in range(rows_count):
        row = tuple(values[cursor:cursor + dimensions])
        cursor += dimensions
        measure = values[cursor]
        cursor += 1
        if any(x < 0 or x > 7 for x in row) or measure < 0 or measure > 1000:
            return INVALID_RESULT
        tuples.append(row)
        measures.append(measure)

    limit = 1 << dimensions
    # This oracle materializes every raw projection independently. The parent
    # decision uses these direct cardinalities, not the primary oracle's tree.
    direct: dict[int, list[tuple[tuple[int, ...], int]]] = {}
    for mask in range(limit):
        columns = [column for column in range(dimensions) if mask & (1 << column)]
        sums: dict[tuple[int, ...], int] = {}
        for row_index, row in enumerate(tuples):
            projected = tuple(row[column] for column in columns)
            sums[projected] = sums.get(projected, 0) + measures[row_index]
        direct[mask] = sorted(sums.items())

    parent_of = {limit - 1: -1}
    for mask in range(limit):
        if mask == limit - 1:
            continue
        choices = []
        for column in range(dimensions):
            bit = 1 << column
            if mask & bit == 0:
                choices.append((len(direct[mask | bit]), column, mask | bit))
        parent_of[mask] = min(choices)[2]

    answer = 0
    for mask in range(limit):
        groups = direct[mask]
        answer += (mask + 1) * 1_000_000 + (parent_of[mask] + 2) * 10_000 + len(groups) * 1_000
        columns = [column for column in range(dimensions) if mask & (1 << column)]
        for index, (key, total) in enumerate(groups):
            rank = index + 1
            answer += rank * (total + 1)
            for position, column in enumerate(columns):
                answer += rank * (column + 1) * (key[position] + 1)
    return answer
