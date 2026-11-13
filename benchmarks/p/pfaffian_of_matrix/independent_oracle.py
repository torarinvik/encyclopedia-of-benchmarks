"""Pairing-mask recurrence oracle for bounded Pfaffians over F_998244353."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MODULUS = 998244353
MAX_N = 8
MAX_DIMENSION = 2 * MAX_N
MAX_VALID_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 5
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH
            or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    half = values[0]
    if not 1 <= half <= MAX_N:
        return None
    dimension = 2 * half
    if actual_length != 1 + dimension * dimension:
        return None
    entries = values[1:]
    if any(not 0 <= value < MODULUS for value in entries):
        return None
    matrix = [[entries[row * dimension + column] for column in range(dimension)]
              for row in range(dimension)]
    for row in range(dimension):
        if matrix[row][row] != 0:
            return None
        for column in range(row + 1, dimension):
            if (matrix[row][column] + matrix[column][row]) % MODULUS:
                return None
    return dimension, matrix


def _pairing_recurrence(matrix: list[list[int]]) -> int:
    dimension = len(matrix)

    @lru_cache(maxsize=None)
    def pfaffian(mask: int) -> int:
        if mask == 0:
            return 1
        first_bit = mask & -mask
        first = first_bit.bit_length() - 1
        rest = mask ^ first_bit
        value = 0
        sign = 1
        while rest:
            partner_bit = rest & -rest
            partner = partner_bit.bit_length() - 1
            term = matrix[first][partner] * pfaffian(rest ^ partner_bit)
            if sign == 1:
                value += term
            else:
                value -= term
            value %= MODULUS
            sign = -sign
            rest ^= partner_bit
        return value

    return pfaffian((1 << dimension) - 1)


def expected_result(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1
    _, matrix = parsed
    return _pairing_recurrence(matrix)
