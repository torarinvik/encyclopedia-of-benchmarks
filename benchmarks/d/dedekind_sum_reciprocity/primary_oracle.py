"""Euclidean reciprocity evaluation of a scaled classical Dedekind sum."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MODULUS = 100_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_ABS_SCALED_SUM = 3 * MAX_MODULUS * (MAX_MODULUS - 1)
RESULT_OFFSET = MAX_ABS_SCALED_SUM + 1
MAX_RESULT = 2 * MAX_ABS_SCALED_SUM + 1
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
    numerator, modulus = values
    if not 1 <= modulus <= MAX_MODULUS or not 0 <= numerator < modulus:
        return None
    return numerator, modulus


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _scaled_dedekind(numerator: int, modulus: int) -> int:
    """Return 12*k*s(h,k), unwinding the reciprocity law by Euclid."""
    if modulus == 1:
        return 0
    remainder = modulus % numerator
    tail = _scaled_dedekind(remainder, numerator)
    top = (numerator * numerator + modulus * modulus + 1
           - 3 * numerator * modulus - modulus * tail)
    return top // numerator


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    numerator, modulus = parsed
    if _gcd(numerator, modulus) != 1:
        return INVALID_RESULT
    scaled = _scaled_dedekind(numerator, modulus)
    if not -MAX_ABS_SCALED_SUM <= scaled <= MAX_ABS_SCALED_SUM:
        return INVALID_RESULT
    return RESULT_OFFSET + scaled
