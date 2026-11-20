"""Independent direct-window reference without skip tables."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    ALPHABET_SIZE,
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_TEXT_LENGTH,
    MIN_PATTERN_LENGTH,
    NOT_FOUND,
)


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if length is None:
        declared = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(length) is int and length >= 0:
        declared = length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH or declared != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    text_length, pattern_length = values[0], values[1]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return INVALID_RESULT
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(symbol < 0 or symbol >= ALPHABET_SIZE for symbol in text + pattern):
        return INVALID_RESULT
    if pattern_length > text_length:
        return NOT_FOUND
    for start in range(text_length - pattern_length + 1):
        if all(text[start + offset] == pattern[offset]
               for offset in range(pattern_length)):
            return start
    return NOT_FOUND
