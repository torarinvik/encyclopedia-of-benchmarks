"""Independent oracle for the bounded matrix linear-recurrence package."""

from __future__ import annotations

MODULUS = 1_000_000_007
MAX_DIMENSION = 4
MAX_INDEX = 1_000_000
MAX_INPUT_LENGTH = 24
INVALID_RESULT = -1


def _multiply(left: list[list[int]], right: list[list[int]]) -> list[list[int]]:
    dimension = len(left)
    result = [[0] * dimension for _ in range(dimension)]
    for row in range(dimension):
        for column in range(dimension):
            for inner in range(dimension):
                result[row][column] = (
                    result[row][column]
                    + (left[row][inner] % MODULUS * right[inner][column] % MODULUS) % MODULUS
                ) % MODULUS
    return result


def _matrix_power(matrix: list[list[int]], power: int) -> list[list[int]]:
    dimension = len(matrix)
    if all(value == 0 for row in matrix for value in row):
        return [[0] * dimension for _ in range(dimension)]
    result = [[int(row == column) for column in range(dimension)] for row in range(dimension)]
    base = [row[:] for row in matrix]
    while power > 0:
        if power & 1:
            result = _multiply(result, base)
        power >>= 1
        base = _multiply(base, base)
    return result


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Evaluate one source-style matrix recurrence call."""
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    dimension, nth_term, constant_or_sum_included = values[:3]
    if not 1 <= dimension <= MAX_DIMENSION or not 0 <= nth_term <= MAX_INDEX:
        return INVALID_RESULT
    if constant_or_sum_included not in (0, 1):
        return INVALID_RESULT
    matrix_cells = dimension * dimension
    expected_length = 3 + matrix_cells + dimension
    if len(values) != expected_length:
        return INVALID_RESULT
    if constant_or_sum_included == 1 and nth_term < dimension - 1:
        return INVALID_RESULT

    matrix_values = values[3:3 + matrix_cells]
    base_row = values[3 + matrix_cells:]
    if any(not 0 <= value < MODULUS for value in matrix_values + base_row):
        return INVALID_RESULT
    matrix = [matrix_values[row * dimension:(row + 1) * dimension]
              for row in range(dimension)]

    if nth_term < dimension - constant_or_sum_included:
        return base_row[nth_term - constant_or_sum_included]

    power = nth_term - dimension + 1 + constant_or_sum_included
    powered = _matrix_power(matrix, power)
    result = 0
    for index in range(dimension):
        result = (result + base_row[index] * powered[index][dimension - 1]) % MODULUS
    return result
