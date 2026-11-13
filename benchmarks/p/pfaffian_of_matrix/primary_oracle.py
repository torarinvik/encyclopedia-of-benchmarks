"""Pivoted elimination oracle for bounded Pfaffians over F_998244353."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998244353
MAX_N = 8
MAX_DIMENSION = 2 * MAX_N
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 5
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    half = values[0]
    if not 1 <= half <= MAX_N:
        return None
    dimension = 2 * half
    if input_length != 1 + dimension * dimension:
        return None
    flat = values[1:]
    if any(value < 0 or value >= MODULUS for value in flat):
        return None
    matrix = [list(flat[row * dimension:(row + 1) * dimension])
              for row in range(dimension)]
    for row in range(dimension):
        if matrix[row][row] != 0:
            return None
        for column in range(row + 1, dimension):
            if (matrix[row][column] + matrix[column][row]) % MODULUS != 0:
                return None
    return matrix


def _normalize(value: int) -> int:
    return value % MODULUS


def _power(base: int, exponent: int) -> int:
    result = 1
    while exponent:
        if exponent & 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result


def _pfaffian_by_elimination(matrix: list[list[int]]) -> int:
    work = [row[:] for row in matrix]
    dimension = len(work)
    result = 1
    for pivot_index in range(0, dimension, 2):
        partner = pivot_index + 1
        while partner < dimension and work[pivot_index][partner] == 0:
            partner += 1
        if partner == dimension:
            return 0
        if partner != pivot_index + 1:
            swap_index = pivot_index + 1
            work[swap_index], work[partner] = work[partner], work[swap_index]
            for row in range(dimension):
                work[row][swap_index], work[row][partner] = (
                    work[row][partner], work[row][swap_index]
                )
            result = (-result) % MODULUS

        pivot = work[pivot_index][pivot_index + 1]
        result = result * pivot % MODULUS
        inverse = _power(pivot, MODULUS - 2)
        for row in range(pivot_index + 2, dimension):
            for column in range(row + 1, dimension):
                cross = (work[pivot_index][row] * work[pivot_index + 1][column]
                         - work[pivot_index][column] * work[pivot_index + 1][row])
                value = (work[row][column] - cross * inverse) % MODULUS
                work[row][column] = value
                work[column][row] = (-value) % MODULUS
    return result


def expected_result(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    matrix = _parse(values, input_length, input_is_null)
    if matrix is None:
        return INVALID_RESULT
    return _pfaffian_by_elimination(matrix)
