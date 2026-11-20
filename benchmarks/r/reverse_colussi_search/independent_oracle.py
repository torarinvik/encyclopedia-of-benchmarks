"""Exhaustive direct alignment scan, independent of Reverse Colussi tables."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX, I64_MIN, MAX_PARSEABLE_INPUT_LENGTH, MAX_PATTERN_LENGTH,
    MAX_SYMBOL, MAX_TEXT_LENGTH,
)


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) < 2:
        return -1
    n, m = values[:2]
    if (not 0 <= n <= MAX_TEXT_LENGTH or not 1 <= m <= MAX_PATTERN_LENGTH
            or len(values) != 2 + n + m):
        return -1
    text = values[2:2 + n]
    pattern = values[2 + n:]
    if any(symbol < 0 or symbol > MAX_SYMBOL for symbol in text + pattern):
        return -1
    count = 0
    offset_sum = 0
    offset_xor = 0
    for start in range(n - m + 1):
        for offset in range(m):
            if text[start + offset] != pattern[offset]:
                break
        else:
            count += 1
            offset_sum += start
            offset_xor ^= start
    return (count << 36) | (offset_sum << 12) | offset_xor
