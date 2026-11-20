"""Euclidean quadratic-reciprocity algorithm for the Jacobi symbol."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MODULUS = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = 2
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or input_length != 2:
        return None
    numerator, denominator = values
    if (not 1 <= denominator <= MAX_MODULUS or denominator % 2 == 0
            or not 0 <= numerator < denominator):
        return None
    return numerator, denominator


def _jacobi_reciprocity(numerator: int, denominator: int) -> int:
    sign = 1
    while numerator != 0:
        while (numerator & 1) == 0:
            numerator //= 2
            if denominator % 8 in (3, 5):
                sign = -sign
        if numerator % 4 == 3 and denominator % 4 == 3:
            sign = -sign
        numerator, denominator = denominator, numerator
        numerator %= denominator
    return sign if denominator == 1 else 0


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    numerator, denominator = parsed
    return _jacobi_reciprocity(numerator, denominator) + 1
