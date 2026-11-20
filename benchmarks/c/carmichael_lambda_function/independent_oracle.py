"""Unit-group element-order enumeration for the Carmichael exponent."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MAX_N = 1_024
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 1:
        return None
    n = values[0]
    if not 1 <= n <= MAX_N:
        return None
    return n


def _element_order(value: int, modulus: int) -> int:
    power = 1
    for exponent in range(1, modulus + 1):
        power = power * value % modulus
        if power == 1:
            return exponent
    raise AssertionError("a unit's multiplicative order must divide the group size")


def _unit_group_exponent(n: int) -> int:
    if n == 1:
        return 1
    exponent = 1
    for value in range(1, n):
        if gcd(value, n) != 1:
            continue
        order = _element_order(value, n)
        exponent = exponent // gcd(exponent, order) * order
    return exponent


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _decode(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT
    return _unit_group_exponent(n)


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return type(result) is int and result == expected_result(values, input_is_null, input_length)
