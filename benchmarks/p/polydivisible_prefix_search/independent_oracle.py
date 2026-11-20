"""Exhaustively test each number's prefixes, without a prefix-tree search."""

from __future__ import annotations

from collections.abc import Sequence

MIN_BASE = 2
MAX_BASE = 10
MIN_DIGITS = 1
MAX_DIGITS = 6
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
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


def _has_divisible_prefixes(number: int, base: int, digits: int) -> bool:
    divisor = 1
    for place in range(digits - 1, -1, -1):
        digit = number // (base ** place) % base
        divisor = divisor * base + digit if place != digits - 1 else digit
        prefix_length = digits - place
        if divisor % prefix_length != 0:
            return False
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    base, max_digits = parsed
    count = 0
    for digits in range(1, max_digits + 1):
        lower = base ** (digits - 1)
        upper = base ** digits
        for number in range(lower, upper):
            if _has_divisible_prefixes(number, base, digits):
                count += 1
    return count
