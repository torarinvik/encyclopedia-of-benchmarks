"""Independent determinant/Cramer reference for bounded Padé coefficients."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MODULUS = 998244353
MAX_VALID_INPUT_LENGTH = 11
MAX_PARSEABLE_INPUT_LENGTH = 12
MAX_OUTPUT_WORDS = 12
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
WORKSPACE_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
SINGULAR_RESULT = -3


def _input(values: Sequence[int] | None, is_null: bool,
           length: int | None) -> tuple[int, int, list[int]] | None:
    if (type(is_null) is not bool or is_null or not isinstance(values, (list, tuple))
            or (length is not None and (type(length) is not int or length != len(values)))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    p, q = values[0], values[1]
    if not 1 <= q <= p <= 4 or len(values) != p + q + 3:
        return None
    coeff = list(values[2:])
    if len(coeff) != p + q + 1 or any(v < 0 or v >= MODULUS for v in coeff):
        return None
    return p, q, coeff


def _determinant(matrix: Sequence[Sequence[int]]) -> int:
    n = len(matrix)
    total = 0
    for permutation in itertools.permutations(range(n)):
        inversions = sum(permutation[i] > permutation[j]
                         for i in range(n) for j in range(i + 1, n))
        product = 1
        for row, column in enumerate(permutation):
            product = product * matrix[row][column] % MODULUS
        total = (total + (-product if inversions & 1 else product)) % MODULUS
    return total


def _cramer_solution(p: int, q: int, coeff: Sequence[int]) -> list[int] | None:
    matrix: list[list[int]] = []
    rhs: list[int] = []
    for row in range(q):
        m = p + 1 + row
        matrix.append([coeff[m - j] for j in range(1, q + 1)])
        rhs.append((-coeff[m]) % MODULUS)
    determinant = _determinant(matrix)
    if determinant == 0:
        return None
    inverse = pow(determinant, MODULUS - 2, MODULUS)
    tail: list[int] = []
    for column in range(q):
        replaced = [row.copy() for row in matrix]
        for r in range(q):
            replaced[r][column] = rhs[r]
        tail.append(_determinant(replaced) * inverse % MODULUS)
    denominator = [1, *tail]
    numerator: list[int] = []
    for degree in range(p + 1):
        numerator.append(sum(coeff[degree - j] * denominator[j]
                             for j in range(min(degree, q) + 1)) % MODULUS)
    return [p, q, *numerator, *denominator]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _input(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    p, q, coeff = parsed
    required = 8 * (p + q + 4)
    cap = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(cap) is not int or cap < required):
        return OUTPUT_ERROR_RESULT, b""
    result = _cramer_solution(p, q, coeff)
    if result is None:
        return SINGULAR_RESULT, b""
    return required, struct.pack("<" + "q" * len(result), *result)
