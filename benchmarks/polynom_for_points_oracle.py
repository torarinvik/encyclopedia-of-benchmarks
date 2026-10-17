"""Bounded oracle for the pinned polynomial-through-points routine."""

from __future__ import annotations

import math
import struct

MIN_POINTS = 2
MAX_POINTS = 8
MIN_X = -4
MAX_X = 4
MIN_Y = -25_000
MAX_Y = 25_000
MAX_COEFFICIENT = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
MAX_OUTPUT_BYTES = 124
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _coefficients(values: list[int] | tuple[int, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(value) is not int for value in values)
            or len(values) > MAX_INPUT_LENGTH):
        return None
    n = values[0]
    if type(n) is not int or not MIN_POINTS <= n <= MAX_POINTS or len(values) != 1 + 2 * n:
        return None
    points = [(values[1 + 2 * index], values[2 + 2 * index]) for index in range(n)]
    if (any(not MIN_X <= x <= MAX_X or not MIN_Y <= y <= MAX_Y for x, y in points)
            or len({x for x, _ in points}) != n):
        return None

    matrix = [
        [float(x ** (n - column - 1)) for column in range(n)]
        for x, _ in points
    ]
    vector = [float(y) for _, y in points]
    for count in range(n):
        if matrix[count][count] == 0.0:
            pivot_row = max(
                range(count + 1, n), key=lambda row: abs(matrix[row][count])
            )
            if pivot_row == count or matrix[pivot_row][count] == 0.0:
                return None
            matrix[count], matrix[pivot_row] = matrix[pivot_row], matrix[count]
            vector[count], vector[pivot_row] = vector[pivot_row], vector[count]
        for number in range(n):
            if count == number:
                continue
            fraction = matrix[number][count] / matrix[count][count]
            for column, item in enumerate(matrix[count]):
                matrix[number][column] -= item * fraction
            vector[number] -= vector[count] * fraction

    result = [vector[index] / matrix[index][index] for index in range(n)]
    if any(not math.isfinite(value) or abs(value) > MAX_COEFFICIENT
           or value != math.trunc(value) for value in result):
        return None
    return result


def expected_output(
    values: list[int] | tuple[int, ...],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the bounded source-format polynomial as ASCII bytes."""
    if capacity is not None and type(capacity) is not int:
        return INVALID_RESULT, b""
    coefficients = _coefficients(values)
    if coefficients is None or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    n = values[0]
    text = "f(x)=" + "+".join(
        f"x^{n - index - 1}*{coefficient}"
        for index, coefficient in enumerate(coefficients)
    )
    output = text.encode("ascii")
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
