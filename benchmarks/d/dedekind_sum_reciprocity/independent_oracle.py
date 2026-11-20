"""Direct finite-sum oracle for the scaled classical Dedekind sum."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

INVALID_RESULT = -1
MAX_MODULUS = 100_000
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_ABS_SCALED_SUM = 3 * MAX_MODULUS * (MAX_MODULUS - 1)
RESULT_OFFSET = MAX_ABS_SCALED_SUM + 1


def _read(values: Sequence[int] | None, input_is_null: bool,
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
    if gcd(numerator, modulus) != 1:
        return None
    return numerator, modulus


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    numerator, modulus = parsed

    # ((j/k)) = (2j-k)/(2k) for 1<=j<k. The other sawtooth
    # factor is zero when its residue is zero, matching the definition.
    product_numerator_sum = 0
    for j in range(1, modulus):
        residue = (numerator * j) % modulus
        left = 2 * j - modulus
        right = 0 if residue == 0 else 2 * residue - modulus
        product_numerator_sum += left * right
    scaled_numerator = 3 * product_numerator_sum
    if scaled_numerator % modulus != 0:
        return INVALID_RESULT
    scaled = scaled_numerator // modulus
    if not -MAX_ABS_SCALED_SUM <= scaled <= MAX_ABS_SCALED_SUM:
        return INVALID_RESULT
    return RESULT_OFFSET + scaled


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
