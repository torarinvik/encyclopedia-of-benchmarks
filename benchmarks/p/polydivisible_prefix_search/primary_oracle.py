"""Incremental prefix-tree search for bounded polydivisible values."""

from __future__ import annotations

from collections.abc import Sequence

MIN_BASE = 2
MAX_BASE = 10
MIN_DIGITS = 1
MAX_DIGITS = 6
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = 999_999
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 2:
        return None
    base, max_digits = values
    if not MIN_BASE <= base <= MAX_BASE or not MIN_DIGITS <= max_digits <= MAX_DIGITS:
        return None
    return base, max_digits


def _extend(prefix: int, digits: int, base: int, max_digits: int) -> int:
    count = 1
    if digits == max_digits:
        return count
    next_length = digits + 1
    for digit in range(base):
        candidate = prefix * base + digit
        if candidate % next_length == 0:
            count += _extend(candidate, next_length, base, max_digits)
    return count


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    base, max_digits = parsed
    return sum(_extend(first_digit, 1, base, max_digits)
               for first_digit in range(1, base))
