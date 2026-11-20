"""Independent direct-window oracle for Optimal Mismatch."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_TEXT_LENGTH,
    MAX_PATTERN_LENGTH,
    MIN_PATTERN_LENGTH,
    NOT_FOUND,
)


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Validate the frame, then test candidate starts without shift tables."""
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if length is None:
        declared = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(length) is int and length >= 0:
        declared = length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (tuple, list)) or len(values) != declared
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return INVALID_RESULT

    n, m = values[0], values[1]
    if (n < 0 or n > MAX_TEXT_LENGTH or m < MIN_PATTERN_LENGTH
            or m > MAX_PATTERN_LENGTH or len(values) != n + m + 2):
        return INVALID_RESULT
    split = 2 + n
    text = values[2:split]
    pattern = values[split:]
    if any(byte < 0 or byte > 127 for byte in text + pattern):
        return INVALID_RESULT
    if m > n:
        return NOT_FOUND

    start = 0
    while start + m <= n:
        offset = 0
        while offset < m and text[start + offset] == pattern[offset]:
            offset += 1
        if offset == m:
            return start
        start += 1
    return NOT_FOUND
