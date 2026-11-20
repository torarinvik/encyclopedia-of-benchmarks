"""Iterative recurrence oracle for the final nonzero decimal digit of n!."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = (1 << 63) - 1
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

_DIGIT_FACTOR = (1, 1, 2, 6, 4)
_TWO_POWER_MOD_10 = (1, 2, 4, 8)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> int | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX
           for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    n = values[0]
    if not 0 <= n <= MAX_N:
        return None
    return n


def expected_result(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return D(n) by repeatedly applying the divide-by-five recurrence."""
    n = _parse(values, input_length, input_is_null)
    if n is None:
        return -1

    result = 1
    while n >= 5:
        quotient, remainder = divmod(n, 5)
        result = (result * _DIGIT_FACTOR[remainder]
                  * _TWO_POWER_MOD_10[quotient % 4]) % 10
        n = quotient
    return result * _DIGIT_FACTOR[n] % 10


factorial_last_nonzero_digit = expected_result
