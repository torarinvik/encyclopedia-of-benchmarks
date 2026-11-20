"""Independent direct-window reference for Not So Naive fixtures."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_TEXT_LENGTH,
    MIN_PATTERN_LENGTH,
    NOT_FOUND,
)


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Validate the packed byte frame, then test windows from left to right."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if length is None:
        declared = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(length) is int and length >= 0:
        declared = length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or declared != len(values)):
        return INVALID_RESULT
    text_size, pattern_size = values[0], values[1]
    if (not 0 <= text_size <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= pattern_size <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_size + pattern_size):
        return INVALID_RESULT
    text_begin = 2
    pattern_begin = text_begin + text_size
    text = values[text_begin:pattern_begin]
    pattern = values[pattern_begin:]
    if any(byte < 0 or byte > 127 for byte in (*text, *pattern)):
        return INVALID_RESULT
    final_start = text_size - pattern_size
    for start in range(final_start + 1):
        offset = 0
        while offset < pattern_size and text[start + offset] == pattern[offset]:
            offset += 1
        if offset == pattern_size:
            return start
    return NOT_FOUND
