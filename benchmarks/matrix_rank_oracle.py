"""Exact-arithmetic oracle for the bounded binary matrix-rank benchmark."""

from __future__ import annotations

from fractions import Fraction

MAX_INPUT_LENGTH = 66
MAX_DIMENSION = 8


def expected_result(values: list[int]) -> int:
    if (
        not isinstance(values, list)
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return -1

    rows, cols = values[:2]
    if not 1 <= rows <= MAX_DIMENSION or not 1 <= cols <= MAX_DIMENSION:
        return -1
    if len(values) != 2 + rows * cols:
        return -1
    cells = values[2:]
    if any(value not in (0, 1) for value in cells):
        return -1

    matrix = [
        [Fraction(cells[row * cols + col]) for col in range(cols)]
        for row in range(rows)
    ]
    rank = 0
    for col in range(cols):
        pivot = next((row for row in range(rank, rows) if matrix[row][col] != 0), None)
        if pivot is None:
            continue
        matrix[rank], matrix[pivot] = matrix[pivot], matrix[rank]
        pivot_value = matrix[rank][col]
        matrix[rank] = [value / pivot_value for value in matrix[rank]]
        for row in range(rank + 1, rows):
            factor = matrix[row][col]
            if factor != 0:
                matrix[row] = [
                    value - factor * pivot_entry
                    for value, pivot_entry in zip(matrix[row], matrix[rank])
                ]
        rank += 1
        if rank == rows:
            break
    return rank
