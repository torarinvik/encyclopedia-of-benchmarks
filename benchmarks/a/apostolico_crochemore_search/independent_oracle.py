"""Brute-force all-occurrences reference for bounded byte strings."""

from __future__ import annotations

from .primary_oracle import (
    COUNT_SHIFT,
    I64_MAX,
    I64_MIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_TEXT_LENGTH,
    SUM_SHIFT,
)


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if len(values) != 2 + text_length + pattern_length:
        return None
    text = tuple(values[2:2 + text_length])
    pattern = tuple(values[2 + text_length:])
    if any(not 0 <= value <= 3 for value in text + pattern):
        return None
    return text, pattern


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    pattern_length = len(pattern)
    offsets = [
        start for start in range(len(text) - pattern_length + 1)
        if text[start:start + pattern_length] == pattern
    ]
    count = len(offsets)
    offset_sum = sum(offsets)
    offset_xor = 0
    for offset in offsets:
        offset_xor ^= offset
    return (count << COUNT_SHIFT) | (offset_sum << SUM_SHIFT) | offset_xor
