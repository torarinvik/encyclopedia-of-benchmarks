"""Exhaustive bounded oracle for Stoer–Wagner global minimum cut."""

from __future__ import annotations

MAX_N = 16
MAX_WEIGHT = 1_000_000
MAX_INPUT_VALUES = 1 + MAX_N * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the minimum undirected cut weight, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 1 + n * n:
        return INVALID_RESULT

    matrix = [values[1 + row * n : 1 + (row + 1) * n] for row in range(n)]
    for row in range(n):
        if matrix[row][row] != 0:
            return INVALID_RESULT
        for column in range(n):
            weight = matrix[row][column]
            if not 0 <= weight <= MAX_WEIGHT or weight != matrix[column][row]:
                return INVALID_RESULT

    full = (1 << n) - 1
    minimum: int | None = None
    for side in range(1, full):
        if side & 1 == 0:
            continue
        cut = 0
        for row in range(n):
            if side & (1 << row):
                for column in range(n):
                    if side & (1 << column) == 0:
                        cut += matrix[row][column]
        if minimum is None or cut < minimum:
            minimum = cut
    return 0 if minimum is None else minimum
