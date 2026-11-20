"""Packed generator bitmap for counting positive base-10 self-numbers."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "self_number_count_sieve"
MAX_LIMIT = 100_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MIN_RESULT = 1
MAX_RESULT = MAX_LIMIT
MAX_GENERATOR_WORDS = 1_563
MAX_WORKSPACE_BYTES = 16_384
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    limit = values[0]
    if not 1 <= limit <= MAX_LIMIT:
        return None
    return limit


def _digit_sum10(value: int) -> int:
    total = 0
    while value:
        total += value % 10
        value //= 10
    return total


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Count self-numbers in the inclusive positive interval [1, N]."""
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT

    generated = [0] * MAX_GENERATOR_WORDS
    for source in range(1, limit + 1):
        target = source + _digit_sum10(source)
        if target <= limit:
            generated[target >> 6] |= 1 << (target & 63)

    count = 0
    for value in range(1, limit + 1):
        if generated[value >> 6] & (1 << (value & 63)) == 0:
            count += 1
    return count
