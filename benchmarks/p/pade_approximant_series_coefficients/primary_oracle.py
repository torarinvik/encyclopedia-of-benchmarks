"""Primary modular Gauss-Jordan reference for a bounded Padé entry."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "pade_approximant_series_coefficients"
MODULUS = 998244353
MIN_P = 1
MAX_P = 4
MAX_Q = 4
MAX_VALID_INPUT_LENGTH = 11
MAX_PARSEABLE_INPUT_LENGTH = 12
MAX_OUTPUT_WORDS = 12
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
WORKSPACE_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
SINGULAR_RESULT = -3


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    p, q = values[0], values[1]
    if not MIN_P <= q <= p <= MAX_P or len(values) != p + q + 3:
        return None
    coefficients = list(values[2:])
    if len(coefficients) != p + q + 1 or any(not 0 <= c < MODULUS for c in coefficients):
        return None
    return p, q, coefficients


def _system(p: int, q: int, c: Sequence[int]) -> list[list[int]]:
    matrix: list[list[int]] = []
    for row in range(q):
        m = p + 1 + row
        matrix.append([c[m - j] for j in range(1, q + 1)] + [(-c[m]) % MODULUS])
    return matrix


def _gauss_jordan(p: int, q: int, c: Sequence[int]) -> list[int] | None:
    matrix = _system(p, q, c)
    for column in range(q):
        pivot = next((row for row in range(column, q)
                      if matrix[row][column] % MODULUS != 0), None)
        if pivot is None:
            return None
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        inverse = pow(matrix[column][column], MODULUS - 2, MODULUS)
        for j in range(column, q + 1):
            matrix[column][j] = matrix[column][j] * inverse % MODULUS
        for row in range(q):
            if row == column:
                continue
            factor = matrix[row][column]
            if factor:
                for j in range(column, q + 1):
                    matrix[row][j] = (matrix[row][j] - factor * matrix[column][j]) % MODULUS
    return [matrix[j][q] for j in range(q)]


def pade_coefficients(p: int, q: int, coefficients: Sequence[int]) -> list[int] | None:
    denominator_tail = _gauss_jordan(p, q, coefficients)
    if denominator_tail is None:
        return None
    denominator = [1, *denominator_tail]
    numerator: list[int] = []
    for m in range(p + 1):
        total = 0
        for j in range(min(m, q) + 1):
            total = (total + coefficients[m - j] * denominator[j]) % MODULUS
        numerator.append(total)
    return [p, q, *numerator, *denominator]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    p, q, coefficients = parsed
    words = p + q + 4
    required = 8 * words
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    result = pade_coefficients(p, q, coefficients)
    if result is None:
        return SINGULAR_RESULT, b""
    return required, struct.pack("<" + "q" * len(result), *result)
