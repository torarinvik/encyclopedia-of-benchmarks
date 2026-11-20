"""Exhaust every bounded leading-1 decimal string over digits zero and one."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return None
    return values[0]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT

    best = MAX_N + 1
    for digits in range(1, n + 1):
        suffix_width = digits - 1
        for suffix in range(1 << suffix_width):
            number = 1
            for bit_position in range(suffix_width - 1, -1, -1):
                number = number * 10 + ((suffix >> bit_position) & 1)
            digit_sum = 1 + suffix.bit_count()
            if number % n == 0 and digit_sum < best:
                best = digit_sum
    return best if best <= MAX_N else INVALID_RESULT
