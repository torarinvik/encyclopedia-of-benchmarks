"""Direct bounded predecessor search for the self-number count."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, MAX_LIMIT, MAX_PARSEABLE_INPUT_LENGTH


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values) or len(values) != 1:
        return None
    if not 1 <= values[0] <= MAX_LIMIT:
        return None
    return values[0]


def _digit_sum10(value: int) -> int:
    total = 0
    while value:
        total += value % 10
        value //= 10
    return total


def _has_positive_generator(value: int) -> bool:
    digits = len(str(value))
    first_possible = max(1, value - 9 * digits)
    for source in range(first_possible, value):
        if source + _digit_sum10(source) == value:
            return True
    return False


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Count values with no positive digit-addition predecessor."""
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT
    return sum(not _has_positive_generator(value) for value in range(1, limit + 1))
