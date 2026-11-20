"""Hankel-minor determinant reference for the finite-field S-fraction."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MODULUS = 998_244_353
MIN_N = 2
MAX_N = 9
MAX_VALID_INPUT_LENGTH = 10
MAX_PARSEABLE_INPUT_LENGTH = 11
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 0


def _encode_i64(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    count = values[0]
    if not MIN_N <= count <= MAX_N or len(values) != count + 1:
        return None
    coefficients = list(values[1:])
    if any(not 1 <= value < MODULUS for value in coefficients):
        return None
    return count, coefficients


def _determinant(matrix: list[list[int]]) -> int:
    size = len(matrix)

    def expand(row: int, used_columns: int) -> int:
        if row == size:
            return 1
        total = 0
        for column in range(size):
            if (used_columns >> column) & 1:
                continue
            inversions = (used_columns >> (column + 1)).bit_count()
            term = matrix[row][column] * expand(row + 1, used_columns | (1 << column))
            total += -term if inversions & 1 else term
        return total % MODULUS

    return expand(0, 0)


def _convert(coefficients: list[int]) -> list[int] | None:
    count = len(coefficients)

    @lru_cache(maxsize=None)
    def hankel(size: int, shift: int) -> int:
        if size == 0:
            return 1
        matrix = [
            [coefficients[shift + row + column] for column in range(size)]
            for row in range(size)
        ]
        return _determinant(matrix)

    def q_cell(row: int, shift: int) -> int | None:
        numerator = hankel(row, shift + 1) * hankel(row - 1, shift) % MODULUS
        denominator = hankel(row, shift) * hankel(row - 1, shift + 1) % MODULUS
        if denominator == 0:
            return None
        return numerator * pow(denominator, MODULUS - 2, MODULUS) % MODULUS

    def e_cell(row: int, shift: int) -> int | None:
        numerator = hankel(row + 1, shift) * hankel(row - 1, shift + 1) % MODULUS
        denominator = hankel(row, shift) * hankel(row, shift + 1) % MODULUS
        if denominator == 0:
            return None
        return numerator * pow(denominator, MODULUS - 2, MODULUS) % MODULUS

    # Match every quotient operation required by the retained Q-D triangle.
    for row in range(1, 5):
        last_q = count - 2 * row - 2
        if last_q < 0:
            break
        for shift in range(last_q + 1):
            pivot = e_cell(row, shift)
            if pivot is None or pivot == 0:
                return None

    output = [count, coefficients[0]]
    for index in range(1, count):
        if index & 1:
            value = q_cell((index + 1) // 2, 0)
        else:
            value = e_cell(index // 2, 0)
        if value is None:
            return None
        output.append(value)
    return output


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    _, coefficients = parsed
    converted = _convert(coefficients)
    if converted is None:
        return -1, b""
    required = 8 * len(converted)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""
    return required, b"".join(_encode_i64(value) for value in converted)
