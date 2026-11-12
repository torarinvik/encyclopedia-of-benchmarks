"""Independent companion-matrix exponentiation oracle for recurrence terms."""

from __future__ import annotations

from collections.abc import Sequence

from bostan_mori_recurrence_term_oracle import (
    MAX_INDEX,
    MAX_ORDER,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MODULUS,
)


def _multiply(left: list[list[int]], right: list[list[int]]) -> list[list[int]]:
    size = len(left)
    product = [[0] * size for _ in range(size)]
    for row in range(size):
        for pivot in range(size):
            if left[row][pivot] == 0:
                continue
            for column in range(size):
                product[row][column] = (
                    product[row][column] + left[row][pivot] * right[pivot][column]
                ) % MODULUS
    return product


def _apply(matrix: list[list[int]], vector: list[int]) -> list[int]:
    return [sum(value * vector[column] for column, value in enumerate(row)) % MODULUS
            for row in matrix]


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 2:
        return -1
    order, index = values[0], values[1]
    if (type(order) is not int or not 1 <= order <= MAX_ORDER
            or type(index) is not int or not 0 <= index <= MAX_INDEX
            or len(values) != 2 + 2 * order):
        return -1

    coefficients = list(values[2:2 + order])
    initial = list(values[2 + order:])
    if any(type(value) is not int or not 0 <= value < MODULUS
           for value in (*coefficients, *initial)):
        return -1
    if index < order:
        return initial[index]

    transition = [[0] * order for _ in range(order)]
    transition[0] = coefficients
    for row in range(1, order):
        transition[row][row - 1] = 1
    state = list(reversed(initial))
    exponent = index - order + 1
    while exponent:
        if exponent & 1:
            state = _apply(transition, state)
        exponent >>= 1
        if exponent:
            transition = _multiply(transition, transition)
    return state[0]
