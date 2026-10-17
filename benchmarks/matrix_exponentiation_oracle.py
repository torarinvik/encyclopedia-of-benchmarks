"""Oracle for the bounded pinned C++ linear-recurrence matrix exponentiation."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_ORDER = 8
MAX_INDEX = 1_000_000_000_000
MAX_INPUT_LENGTH = 2 * MAX_ORDER + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _multiply(left: list[list[int]], right: list[list[int]]) -> list[list[int]]:
    """Multiply matrices with the source's per-product and per-sum reductions."""
    dimension = len(left)
    result = [[0] * dimension for _ in range(dimension)]
    for row in range(dimension):
        for column in range(dimension):
            for inner in range(dimension):
                result[row][column] = (
                    result[row][column]
                    + (left[row][inner] * right[inner][column]) % MODULUS
                ) % MODULUS
    return result


def _power(matrix: list[list[int]], exponent: int) -> list[list[int]]:
    """Match the pinned p==1, odd p-1, and even square recursion."""
    if exponent == 1:
        return [row[:] for row in matrix]
    if exponent % 2 == 1:
        return _multiply(matrix, _power(matrix, exponent - 1))
    half_power = _power(matrix, exponent // 2)
    return _multiply(half_power, half_power)


def expected_result(values: Sequence[int] | None) -> int:
    """Return the nth term of the bounded recurrence, or -1 for invalid input."""
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    order = values[0]
    if not 1 <= order <= MAX_ORDER:
        return INVALID_RESULT
    if len(values) != 2 * order + 2:
        return INVALID_RESULT

    initial = values[1 : 1 + order]
    coefficients = values[1 + order : 1 + 2 * order]
    index = values[-1]
    if any(not 0 <= value < MODULUS for value in initial + coefficients):
        return INVALID_RESULT
    if not 0 <= index <= MAX_INDEX:
        return INVALID_RESULT

    if index == 0:
        return 0
    if index <= order:
        return initial[index - 1]

    transition = [[0] * order for _ in range(order)]
    for row in range(order - 1):
        transition[row][row + 1] = 1
    transition[-1] = list(reversed(coefficients))
    powered = _power(transition, index - 1)

    result = 0
    for column in range(order):
        result = (result + (powered[0][column] * initial[column]) % MODULUS) % MODULUS
    return result
